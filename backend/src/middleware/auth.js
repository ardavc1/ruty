
import jwt from 'jsonwebtoken';
export function authRequired(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'dev_secret');
    req.user = { id: payload.sub, email: payload.email };
    next();
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
}
