/* CLUB BEE — ใส่ค่าจาก Supabase → Project Settings → API (Data API)
   ถ้าเว้นว่างไว้ แอปจะเปิดในโหมดเดโม (ข้อมูลเก็บในเครื่อง) */
window.CLUBBEE_CONFIG = {
  SUPABASE_URL: '',        // เช่น 'https://abcdefghijk.supabase.co'
  SUPABASE_ANON_KEY: ''    // คีย์ anon / publishable (ปลอดภัยที่จะอยู่ในเว็บ) — ห้ามใส่ service_role
};
