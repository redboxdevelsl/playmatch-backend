const router = require('express').Router();
const { listUsers } = require('../controllers/users.controller');
const { protect } = require('../middleware/auth');

router.get('/', protect, listUsers);

module.exports = router;
