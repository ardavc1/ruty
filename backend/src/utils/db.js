import pg from 'pg';
const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  console.error('Missing DATABASE_URL in environment variables');
  process.exit(1);
}

// IPv4 uyumlu connection string kullanıyoruz
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false, // Supabase için gerekli
  },
  max: 20, // Connection pool size
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000, // 10 saniye timeout
});

// Test connection
pool.on('connect', () => {
  console.log('✅ Database connected successfully');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected database error:', err);
  // Process'i sonlandırma - sadece log'la
  // process.exit(-1);
});

// Test query
export async function testConnection() {
  try {
    const result = await pool.query('SELECT NOW()');
    console.log('✅ Database connection test successful:', result.rows[0]);
    return true;
  } catch (error) {
    console.error('❌ Database connection test failed:', error.message);
    
    // Daha açıklayıcı hata mesajları
    if (error.message.includes('ENOTFOUND') || error.message.includes('getaddrinfo')) {
      console.error('\n🔍 HATA: Database host adresi bulunamadı!');
      console.error('💡 Çözüm: .env dosyasında IPv4 uyumlu connection string kullanın:');
      console.error('   postgresql://postgres.anuccujjqcsifftlxtqg:rutyproje2026@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres');
      console.error('   backend/DATABASE_COZUM.md dosyasına bakın.\n');
    } else if (error.message.includes('password authentication')) {
      console.error('\n🔍 HATA: Database şifresi yanlış!');
      console.error('💡 Çözüm: .env dosyasındaki DATABASE_URL\'deki şifreyi kontrol edin.\n');
    } else if (error.message.includes('timeout')) {
      console.error('\n🔍 HATA: Database bağlantı zaman aşımı!');
      console.error('💡 Çözüm: İnternet bağlantınızı ve Supabase projenizin aktif olduğunu kontrol edin.\n');
    }
    
    return false;
  }
}

