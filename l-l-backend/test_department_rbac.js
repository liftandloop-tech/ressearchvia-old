import axios from 'axios';
import * as dotenv from 'dotenv';
dotenv.config();

async function run() {
    console.log("=== Testing Department-Scoped RBAC ===");

    // 1. Log in as staff to get JWT token
    const loginRes = await axios.post('http://localhost:8080/api/staff/staff-mpin-login', {
        phone: '919893348318',
        mpin: '1234'
    });
    const token = loginRes.data.data.token;
    console.log("✓ Staff login authenticated.");

    const client = axios.create({
        baseURL: 'http://localhost:8080/api',
        headers: { Authorization: token }
    });

    // 2. Fetch pages catalog
    const pagesRes = await client.get('/departments/pages');
    console.log(`✓ Fetched pages catalog: ${pagesRes.data.data.length} available pages.`);
    const samplePage = pagesRes.data.data[0];
    console.log(`   Sample page: ${samplePage.label} (features: ${samplePage.features.join(', ')})`);

    // 3. Fetch departments list
    const deptsRes = await client.get('/departments');
    console.log(`✓ Fetched departments: ${deptsRes.data.data.length} departments found.`);
    deptsRes.data.data.forEach(d => {
        console.log(`   - ${d.name} [${d.code}] (Pages: ${d.assignedPages.join(', ')}${d.isGlobal ? ' - GLOBAL' : ''})`);
    });

    // 4. Create a test department
    const testDeptName = `Test Compliance Dept ${Date.now()}`;
    const createDeptRes = await client.post('/departments', {
        name: testDeptName,
        code: 'COMP',
        description: 'Test Department for compliance checks',
        assignedPages: ['KYC', 'Reports']
    });
    const testDept = createDeptRes.data.data;
    console.log(`✓ Created test department: "${testDept.name}" (ID: ${testDept._id})`);

    // 5. Create a permission group scoped to this department
    const createGroupRes = await client.post('/permission-groups', {
        name: `Compliance Auditor ${Date.now()}`,
        description: 'Audits KYC and research reports',
        departmentId: testDept._id,
        permissions: [
            { feature: 'KYC', actions: ['kyc.view', 'kyc.download_document'] },
            { feature: 'Reports', actions: ['reports.view'] }
        ]
    });
    const testGroup = createGroupRes.data.data;
    console.log(`✓ Created permission group: "${testGroup.name}" linked to department ID: ${testGroup.departmentId?._id || testGroup.departmentId}`);

    // 6. Query permission groups filtered by departmentId
    const filteredGroupsRes = await client.get(`/permission-groups?departmentId=${testDept._id}`);
    console.log(`✓ Query groups by departmentId returned ${filteredGroupsRes.data.data.length} groups.`);
    if (filteredGroupsRes.data.data.length !== 1) {
        throw new Error("Expected 1 filtered group!");
    }

    // 7. Clean up test group and test department
    await client.delete(`/permission-groups/${testGroup._id}`);
    console.log(`✓ Deleted test permission group.`);

    await client.delete(`/departments/${testDept._id}`);
    console.log(`✓ Deleted test department.`);

    console.log("\n=== ALL DEPARTMENT RBAC TESTS PASSED SUCCESSFULLY! ===");
    process.exit(0);
}

run().catch(err => {
    console.error("Test failed:", err.response?.data || err.message);
    process.exit(1);
});
