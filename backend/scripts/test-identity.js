require('dotenv').config();

const fs = require('fs');
const path = require('path');
const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');

async function run() {
  await connectDB();
  await initDefaults();
  await ensureDevAccounts();

  const app = createApp();
  const server = app.listen(0);
  const port = server.address().port;
  const base = `http://127.0.0.1:${port}/api/v1`;

  const loginRes = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'founder@techren.uz', password: 'Founder123!' }),
  });
  const login = await loginRes.json();
  if (!login.success) throw new Error('Founder auto-login failed');

  const studentLoginRes = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'student@techren.uz', password: 'Student123!' }),
  });
  const studentLogin = await studentLoginRes.json();
  if (!studentLogin.success || studentLogin.data?.user?.userType !== 'student') {
    throw new Error('Student auto-login failed');
  }

  const parentLoginRes = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'parent@techren.uz', password: 'Parent123!' }),
  });
  const parentLogin = await parentLoginRes.json();
  if (!parentLogin.success || parentLogin.data?.user?.userType !== 'parent') {
    throw new Error('Parent auto-login failed');
  }

  const headers = { Authorization: `Bearer ${login.data.accessToken}` };
  const dashboard = await (await fetch(`${base}/dashboard`, { headers })).json();
  const branches = await (await fetch(`${base}/branches`, { headers })).json();
  const students = await (await fetch(`${base}/students`, { headers })).json();

  console.log('dashboard role:', dashboard.data?.role);
  console.log('branches count:', branches.data?.length);
  console.log('students count:', students.data?.length);
  console.log('student auto-login:', studentLogin.data?.user?.userType);
  console.log('parent auto-login:', parentLogin.data?.user?.userType);

  const salesLoginRes = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'sales@techren.uz', password: 'Sales123!' }),
  });
  const salesLogin = await salesLoginRes.json();
  if (!salesLogin.success || salesLogin.data?.user?.role !== 'sales') {
    throw new Error('Sales auto-login failed');
  }
  console.log('sales auto-login:', salesLogin.data?.user?.role);

  const receptionLoginRes = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'receptionist@techren.uz', password: 'Reception123!' }),
  });
  const receptionLogin = await receptionLoginRes.json();
  if (!receptionLogin.success || receptionLogin.data?.user?.role !== 'receptionist') {
    throw new Error('Receptionist auto-login failed');
  }
  console.log('receptionist auto-login:', receptionLogin.data?.user?.role);

  const studentId = students.data?.[0]?.id;
  if (studentId) {
    const imagePath = path.join(__dirname, 'fixtures', 'test-image.png');
    if (!fs.existsSync(imagePath)) {
      fs.mkdirSync(path.dirname(imagePath), { recursive: true });
      fs.writeFileSync(
        imagePath,
        Buffer.from(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
          'base64'
        )
      );
    }

    const studentToken = studentLogin.data.accessToken;
    const form = new FormData();
    form.append('photo', new Blob([fs.readFileSync(imagePath)], { type: 'image/png' }), 'profile.png');

    const photoRes = await fetch(`${base}/students/${studentId}/photo`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${studentToken}` },
      body: form,
    });
    const photoJson = await photoRes.json();
    if (!photoJson.success || !photoJson.data?.profileImage) {
      throw new Error('Student photo upload failed');
    }
    console.log('student photo upload:', photoJson.data.profileImage);

    const updateRes = await fetch(`${base}/students/${studentId}`, {
      method: 'PUT',
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: students.data[0].name,
        parentName: 'Updated Parent',
        parentPhone: '+998901112233',
      }),
    });
    const updateJson = await updateRes.json();
    if (!updateJson.success || updateJson.data?.parentName !== 'Updated Parent') {
      throw new Error('Student update failed');
    }
    console.log('student update:', updateJson.data.parentName);
  }

  const teachers = await (await fetch(`${base}/teachers`, { headers })).json();
  const teacherId = teachers.data?.[0]?.id;
  if (teacherId) {
    const teacherUpdateRes = await fetch(`${base}/teachers/${teacherId}`, {
      method: 'PUT',
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: teachers.data[0].name,
        phone: '+998909998877',
      }),
    });
    const teacherUpdateJson = await teacherUpdateRes.json();
    if (!teacherUpdateJson.success || teacherUpdateJson.data?.phone !== '+998909998877') {
      throw new Error('Teacher update failed');
    }
    console.log('teacher update:', teacherUpdateJson.data.phone);

    const teacherStatusRes = await fetch(`${base}/teachers/${teacherId}`, {
      method: 'PUT',
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: 'inactive' }),
    });
    const teacherStatusJson = await teacherStatusRes.json();
    if (!teacherStatusJson.success || teacherStatusJson.data?.status !== 'inactive') {
      throw new Error('Teacher deactivate failed');
    }
    console.log('teacher deactivate:', teacherStatusJson.data.status);
  }

  server.close();
  await disconnectDB();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
