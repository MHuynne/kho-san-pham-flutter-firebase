import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const [projectId, email] = process.argv.slice(2);
if (!projectId || !email) {
  console.error('Cách dùng: node scripts/grant-admin.mjs <project-id> <email>');
  process.exit(1);
}

const app = initializeApp({ projectId, credential: applicationDefault() });
const auth = getAuth(app);
const user = await auth.getUserByEmail(email);
await auth.setCustomUserClaims(user.uid, { ...user.customClaims, admin: true });
console.log(`Đã cấp quyền quản trị cho ${email}. Hãy đăng nhập lại.`);
