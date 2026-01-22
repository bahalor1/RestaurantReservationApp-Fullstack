require('dotenv').config();
const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const nodemailer = require('nodemailer');

// --- GMAIL AYARLARI ---
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'baha.lor34@gmail.com', // BURAYA KENDİ MAİLİNİ YAZ
        pass: 'tybl upjs jupt jken'  // 16 HANELİ ŞİFREYİ YAZ
    }
});

const app = express();
app.use(express.json());
app.use(cors());

const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_DATABASE,
    port: parseInt(process.env.DB_PORT, 10),
    options: {
        encrypt: true,
        trustServerCertificate: true
    }
};

async function startApp() {
    try {
        await sql.connect(dbConfig);
        console.log('✅ SQL Server veritabanına başarıyla bağlanıldı.');

        // ----------------------------------------------------------------
        // 1. AUTH: KAYIT OL (LOG EKLENDİ)
        // ----------------------------------------------------------------
        app.post('/auth/register', async (req, res) => {
            try {
                const { name, email, password, dob } = req.body;

                // --- TERMİNAL LOG ---
                console.log("\n========================================");
                console.log("📝 YENİ KAYIT İSTEĞİ GELDİ");
                console.log(`👤 İsim: ${name}`);
                console.log(`📧 Email: ${email}`);
                console.log("========================================");

                // A. Mail kontrolü
                const checkRequest = new sql.Request();
                checkRequest.input('email', sql.NVarChar, email);
                const userCheck = await checkRequest.query('SELECT * FROM Users WHERE email = @email');

                if (userCheck.recordset.length > 0) {
                    console.log("⚠️ HATA: Bu mail zaten kayıtlı.");
                    return res.status(409).json({ message: 'Bu e-posta zaten kayıtlı.' });
                }

                // B. Rastgele Kod Üret
                const code = Math.floor(100000 + Math.random() * 900000).toString();

                // --- ÖNEMLİ: KODU TERMİNALE YAZDIRIYORUZ ---
                console.log(`🔑 [ÜRETİLEN KOD]: ${code}`);
                console.log("----------------------------------------");

                // C. Kullanıcıyı Users Tablosuna Ekle
                const insertRequest = new sql.Request();
                insertRequest.input('name', sql.NVarChar, name);
                insertRequest.input('email', sql.NVarChar, email);
                insertRequest.input('password', sql.NVarChar, password);
                insertRequest.input('dob', sql.Date, dob);

                await insertRequest.query(`
                    INSERT INTO Users (name, email, password, birth_date) 
                    VALUES (@name, @email, @password, @dob)
                `);

                // D. Doğrulama Kodunu Kaydet
                const codeRequest = new sql.Request();
                codeRequest.input('email', sql.NVarChar, email);
                codeRequest.input('code', sql.VarChar, code);

                await codeRequest.query('DELETE FROM VerificationCodes WHERE email = @email');
                await codeRequest.query('INSERT INTO VerificationCodes (email, code) VALUES (@email, @code)');

                // E. Mail Gönder
                const mailOptions = {
                    from: 'Restoran Uygulaması',
                    to: email,
                    subject: 'Hoşgeldiniz! Doğrulama Kodunuz',
                    text: `Merhaba ${name},\n\nHesabınızı doğrulamak için kodunuz: ${code}\n\nİyi günler!`
                };

                try {
                    await transporter.sendMail(mailOptions);
                    console.log(`✅ Mail başarıyla gönderildi: ${email}`);
                } catch (mailError) {
                    console.error("❌ Mail Hatası:", mailError.message);
                    console.log(`⚠️ Mail gitmediyse lütfen yukarıdaki [ÜRETİLEN KOD] ile test edin.`);
                }

                res.status(201).json({ message: 'Kayıt başarılı. Kod gönderildi.' });

            } catch (err) {
                console.error("❌ Register Hatası:", err);
                res.status(500).json({ message: 'Sunucu hatası: ' + err.message });
            }
        });

        // ----------------------------------------------------------------
        // 2. AUTH: KOD DOĞRULA (LOG EKLENDİ)
        // ----------------------------------------------------------------
        app.post('/auth/verify-code', async (req, res) => {
            try {
                // 1. Gelen verileri zorla String'e çevir ve boşlukları sil
                const email = String(req.body.email).trim();
                const incomingCode = String(req.body.code).trim();

                console.log("\n========================================");
                console.log("🔍 KOD DOĞRULAMA");
                console.log(`📧 Email: ${email}`);
                console.log(`🔢 Gelen Kod: '${incomingCode}' (Tip: ${typeof incomingCode})`);

                const request = new sql.Request();
                request.input('email', sql.NVarChar, email);

                // 2. Veritabanındaki kodu çek
                const result = await request.query('SELECT * FROM VerificationCodes WHERE email = @email');

                if (result.recordset.length === 0) {
                    console.log("❌ DB: Kod bulunamadı!");
                    return res.status(400).json({ message: 'Kod bulunamadı.' });
                }

                // 3. DB'den gelen kodu da zorla String'e çevir
                const dbRecord = result.recordset[0];
                const dbCode = String(dbRecord.code).trim();

                console.log(`💾 DB Kod:    '${dbCode}' (Tip: ${typeof dbCode})`);

                // 4. KARŞILAŞTIRMA
                if (incomingCode === dbCode) {
                    console.log("✅ EŞLEŞTİ! Kod doğru.");
                    // Kodu sil (Tek kullanımlık olsun)
                    await request.query('DELETE FROM VerificationCodes WHERE email = @email');
                    res.status(200).json({ message: 'Kod doğrulandı.' });
                } else {
                    console.log("❌ UYUŞMADI! Kodlar farklı.");
                    res.status(400).json({ message: 'Hatalı kod.' });
                }
                console.log("========================================");

            } catch (err) {
                console.error("Verify Hatası:", err);
                res.status(500).json({ message: 'Sunucu hatası.' });
            }
        });

        // ----------------------------------------------------------------
        // 3. AUTH: GİRİŞ YAP (LOG EKLENDİ)
        // ----------------------------------------------------------------
        app.post('/auth/login', async (req, res) => {
            try {
                const { email, password } = req.body;
                console.log(`\n🔑 [LOGIN] Giriş Denemesi: ${email} | Şifre: ${password}`);

                const request = new sql.Request();
                request.input('email', sql.NVarChar, email);
                request.input('password', sql.NVarChar, password);

                const result = await request.query('SELECT * FROM Users WHERE email = @email AND password = @password');

                const user = result.recordset[0];

                if (user) {
                    console.log(`✅ Giriş Başarılı: ${user.name}`);
                    res.status(200).json({
                        id: user.user_id,
                        name: user.name,
                        email: user.email,
                        birth_date: user.birth_date,
                        message: 'Giriş başarılı'
                    });
                } else {
                    console.log("❌ Giriş Başarısız: Kullanıcı bulunamadı veya şifre yanlış.");
                    res.status(401).json({ message: 'E-posta veya şifre hatalı.' });
                }
            } catch (err) {
                console.error("Login Hatası:", err);
                res.status(500).json({ message: 'Sunucu hatası.' });
            }
        });

        // ----------------------------------------------------------------
        // 4. AUTH: ŞİFRE SIFIRLAMA KODU GÖNDER (LOG EKLENDİ)
        // ----------------------------------------------------------------
        app.post('/auth/send-code', async (req, res) => {
            try {
                const { email } = req.body;
                console.log("\n========================================");
                console.log("🔄 KOD YENİDEN GÖNDERME / ŞİFREMİ UNUTTUM");
                console.log(`📧 İstek Yapan: ${email}`);

                const checkRequest = new sql.Request();
                checkRequest.input('email', sql.NVarChar, email);
                const userCheck = await checkRequest.query('SELECT * FROM Users WHERE email = @email');

                if (userCheck.recordset.length === 0) {
                    console.log("❌ Kullanıcı bulunamadı.");
                    return res.status(404).json({ message: 'Kullanıcı bulunamadı.' });
                }

                const code = Math.floor(100000 + Math.random() * 900000).toString();

                // --- LOG ---
                console.log(`🔑 [YENİ ÜRETİLEN KOD]: ${code}`);
                console.log("========================================");

                const codeRequest = new sql.Request();
                codeRequest.input('email', sql.NVarChar, email);
                codeRequest.input('code', sql.VarChar, code);

                await codeRequest.query('DELETE FROM VerificationCodes WHERE email = @email');
                await codeRequest.query('INSERT INTO VerificationCodes (email, code) VALUES (@email, @code)');

                const mailOptions = {
                    from: 'Restoran Uygulaması',
                    to: email,
                    subject: 'Şifre Sıfırlama Kodu',
                    text: `Şifre sıfırlama kodunuz: ${code}`
                };

                await transporter.sendMail(mailOptions);
                res.status(200).json({ message: 'Doğrulama kodu gönderildi.' });

            } catch (err) {
                console.error(err);
                res.status(500).json({ message: 'Sunucu hatası.' });
            }
        });

        // ----------------------------------------------------------------
        // 5. AUTH: ŞİFREYİ GÜNCELLE
        // ----------------------------------------------------------------
        app.post('/auth/reset-password', async (req, res) => {
            try {
                const { email, newPassword } = req.body;
                const request = new sql.Request();
                request.input('email', sql.NVarChar, email);
                request.input('password', sql.NVarChar, newPassword);

                await request.query('UPDATE Users SET password = @password WHERE email = @email');
                await request.query('DELETE FROM VerificationCodes WHERE email = @email');

                res.status(200).json({ message: 'Şifre güncellendi.' });
            } catch (err) {
                res.status(500).json({ message: 'Hata oluştu.' });
            }
        });

        // ----------------------------------------------------------------
        // 6. ŞİFRE DEĞİŞTİR (ID ile)
        // ----------------------------------------------------------------
        app.put('/users/:id/password', async (req, res) => {
            try {
                const { id } = req.params;
                const { newPassword } = req.body;
                const request = new sql.Request();
                request.input('id', sql.Int, id);
                request.input('password', sql.NVarChar, newPassword);

                await request.query('UPDATE Users SET password = @password WHERE user_id = @id');
                res.status(200).json({ message: 'Şifre güncellendi.' });
            } catch (err) {
                res.status(500).json({ message: 'Hata.' });
            }
        });

        // ----------------------------------------------------------------
        // RESTORAN & REZERVASYON ENDPOINTLERİ
        // ----------------------------------------------------------------
        app.get('/restaurants', async (req, res) => {
            try {
                const { search, category } = req.query;
                const request = new sql.Request();
                let query = "SELECT * FROM Restaurants WHERE 1=1";
                if (search) { query += " AND name LIKE @search"; request.input('search', sql.NVarChar, `%${search}%`); }
                if (category && category !== 'Tümü') { query += " AND cuisine_type LIKE @category"; request.input('category', sql.NVarChar, `%${category}%`); }
                const result = await request.query(query);
                res.status(200).json(result.recordset);
            } catch (err) { res.status(500).json({ message: 'Hata.' }); }
        });

        app.get('/users/:id', async (req, res) => {
            try {
                const { id } = req.params;
                const request = new sql.Request();
                request.input('id', sql.Int, id);
                const result = await request.query('SELECT name, email, birth_date FROM Users WHERE user_id = @id');
                if (result.recordset.length > 0) res.status(200).json(result.recordset[0]);
                else res.status(404).json({ message: 'Kullanıcı yok' });
            } catch (err) { res.status(500).json({ message: 'Hata.' }); }
        });

        app.get('/users/:id/reservations', async (req, res) => {
            try {
                const { id } = req.params;
                const request = new sql.Request();
                request.input('user_id', sql.Int, id);
                const query = `
                    SELECT b.booking_id, b.booking_date, b.party_size, r.name AS restaurant_name, r.image_url, 
                    CONVERT(varchar(5), ts.time_slot, 108) AS time
                    FROM Bookings b
                    INNER JOIN TimeSlots ts ON b.slot_id = ts.slot_id
                    INNER JOIN Restaurants r ON ts.restaurant_id = r.restaurant_id
                    WHERE b.user_id = @user_id
                    ORDER BY b.booking_date DESC, ts.time_slot ASC;
                `;
                const result = await request.query(query);
                res.status(200).json(result.recordset);
            } catch (err) { res.status(500).json({ message: 'Hata.' }); }
        });

        app.get('/restaurants/:id/availability', async (req, res) => {
            try {
                const { id } = req.params;
                const { date } = req.query;
                if (!date) return res.status(400).json({ message: "Tarih gerekli." });
                const request = new sql.Request();
                request.input('restaurant_id', sql.Int, id);
                request.input('date', sql.Date, date);
                const query = `
                    SELECT ts.slot_id, CONVERT(varchar(5), ts.time_slot, 108) AS formatted_time, ts.capacity, 
                    ISNULL(b.total, 0) AS booked, (ts.capacity - ISNULL(b.total, 0)) AS available
                    FROM TimeSlots ts
                    LEFT JOIN (SELECT slot_id, COUNT(*) as total FROM Bookings WHERE booking_date = @date GROUP BY slot_id) b 
                    ON ts.slot_id = b.slot_id
                    WHERE ts.restaurant_id = @restaurant_id
                    ORDER BY ts.time_slot
                `;
                const result = await request.query(query);
                const formatted = result.recordset.map(s => ({
                    slot_id: s.slot_id, time: s.formatted_time, capacity: s.capacity, booked: s.booked, available: s.available
                }));
                res.status(200).json(formatted);
            } catch (err) { res.status(500).json({ message: 'Hata.' }); }
        });

        app.post('/book', async (req, res) => {
            try {
                const { slot_id, booking_date, party_size, user_id } = req.body;
                const request = new sql.Request();
                request.input('user_id', sql.Int, user_id);
                request.input('slot_id', sql.Int, slot_id);
                request.input('booking_date', sql.Date, booking_date);
                request.input('party_size', sql.Int, party_size);
                await request.execute('sp_CreateBooking');
                res.status(201).json({ message: "Rezervasyon oluşturuldu." });
            } catch (err) {
                if (err.message.includes('Kapasite')) res.status(409).json({ message: err.message });
                else res.status(500).json({ message: 'Hata.' });
            }
        });

        app.delete('/bookings/:id', async (req, res) => {
            try {
                const { id } = req.params;
                const request = new sql.Request();
                request.input('id', sql.Int, id);
                await request.query('DELETE FROM Bookings WHERE booking_id = @id');
                res.status(200).json({ message: 'Silindi.' });
            } catch (err) { res.status(500).json({ message: 'Hata.' }); }
        });

        app.delete('/users/:id/history', async (req, res) => {
            try {
                const { id } = req.params;
                const request = new sql.Request();
                request.input('user_id', sql.Int, id);
                await request.query`
                    DELETE b FROM Bookings b
                    INNER JOIN TimeSlots ts ON b.slot_id = ts.slot_id
                    WHERE b.user_id = @user_id
                    AND (b.booking_date < CAST(GETDATE() AS DATE) OR (b.booking_date = CAST(GETDATE() AS DATE) AND ts.time_slot < CAST(GETDATE() AS TIME)))
                `;
                res.status(200).json({ message: 'Geçmiş silindi.' });
            } catch (err) { res.status(500).json({ message: 'Hata.' }); }
        });

        app.delete('/users/:id', async (req, res) => {
            try {
                const { id } = req.params;
                const request = new sql.Request();
                request.input('id', sql.Int, id);
                await request.query('DELETE FROM Bookings WHERE user_id = @id');
                await request.query('DELETE FROM Users WHERE user_id = @id');
                res.status(200).json({ message: 'Hesap silindi.' });
            } catch (err) { res.status(500).json({ message: 'Hata.' }); }
        });

        const PORT = process.env.PORT || 3000;
        app.listen(PORT, () => {
            console.log(`🚀 Sunucu http://localhost:${PORT} adresinde çalışıyor.`);
        });

    } catch (err) {
        console.error('❌ Veritabanı Hatası:', err.message);
    }
}

startApp();