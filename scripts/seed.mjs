import { readFile } from 'node:fs/promises';

const project = 'demo-kho-san-pham';
const auth = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const firestore = `http://127.0.0.1:8080/v1/projects/${project}/databases/(default)/documents`;
const credentials = { email: 'admin@kho.local', password: 'KhoDemo2026!', returnSecureToken: true };

async function request(url, { method = 'GET', body, token } = {}) {
  const response = await fetch(url, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token && { Authorization: `Bearer ${token}` }) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await response.json();
  if (!response.ok) {
    const error = new Error(data.error?.message ?? `HTTP ${response.status}`);
    error.status = response.status;
    throw error;
  }
  return data;
}

async function authCall(action, body) {
  return request(`${auth}/accounts:${action}?key=demo-key`, { method: 'POST', body });
}

try {
  let user;
  try {
    user = await authCall('signUp', credentials);
  } catch (error) {
    if (error.message !== 'EMAIL_EXISTS') throw error;
    user = await authCall('signInWithPassword', credentials);
  }
  await request(`${auth}/projects/${project}/accounts:update`, {
    method: 'POST',
    token: 'owner',
    body: { localId: user.localId, customAttributes: JSON.stringify({ admin: true }) },
  });

  const session = await authCall('signInWithPassword', credentials);
  const products = JSON.parse(await readFile(new URL('../nop-bai/products.json', import.meta.url), 'utf8'));
  for (const [index, product] of products.entries()) {
    const url = `${firestore}/products/demo-${index + 1}?currentDocument.exists=false`;
    try {
      await request(url, {
        method: 'PATCH',
        token: session.idToken,
        body: {
          fields: {
            name: { stringValue: product.name },
            price: { integerValue: String(product.price) },
            soluong: { integerValue: String(product.soluong) },
            image: { stringValue: product.image },
          },
        },
      });
    } catch (error) {
      if (error.status !== 409 && error.status !== 400) throw error;
      if (error.status === 400 && !/already exists/i.test(error.message)) throw error;
    }
  }
  console.log(`Firebase Emulator đã sẵn sàng. Tài khoản demo: ${credentials.email} / ${credentials.password}.`);
} catch (error) {
  console.error('Không thể tạo dữ liệu demo. Hãy bật Firebase Emulator cổng 9099 và 8080.');
  console.error(error.message);
  process.exitCode = 1;
}
