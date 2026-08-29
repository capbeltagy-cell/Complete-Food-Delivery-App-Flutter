const express = require('express');
const multer = require('multer');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const os = require('os');

const app = express();
const PORT = 8091;
const publicHost = '169.58.246.131';
const root = path.join(os.homedir(), 'Desktop', 'Dierb-Images');
const allowedTypes = new Set(['products', 'stores', 'categories', 'profiles']);

for (const dir of allowedTypes) {
  fs.mkdirSync(path.join(root, dir), { recursive: true });
}

app.use(cors());
app.use('/uploads', express.static(root, { fallthrough: false }));

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const requestedType = String(req.body?.type || req.query?.type || 'products').toLowerCase();
    const type = allowedTypes.has(requestedType) ? requestedType : 'products';
    const destination = path.join(root, type);
    fs.mkdirSync(destination, { recursive: true });
    req.dierbUploadType = type;
    cb(null, destination);
  },
  filename: (req, file, cb) => {
    const safeExt = ['.jpg', '.jpeg', '.png', '.webp'].includes(path.extname(file.originalname).toLowerCase())
      ? path.extname(file.originalname).toLowerCase()
      : '.jpg';
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${safeExt}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const ok = ['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype);
    cb(ok ? null : new Error('Only JPG, PNG and WEBP images are allowed'), ok);
  },
});

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'Dierb VPS Uploads', root });
});

app.post('/upload', upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, error: 'No image uploaded' });
  const type = req.dierbUploadType || 'products';
  res.json({
    success: true,
    fileName: req.file.filename,
    type,
    url: `http://${publicHost}:${PORT}/uploads/${type}/${req.file.filename}`,
  });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(400).json({ success: false, error: err.message || 'Upload failed' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('Dierb upload server READY');
  console.log(`http://${publicHost}:${PORT}/health`);
  console.log(`Uploads folder: ${root}`);
});
