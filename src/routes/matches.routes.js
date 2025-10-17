const router = require('express').Router();
const { listMatches, createMatch } = require('../controllers/matches.controller');
const { protect } = require('../middleware/auth');

router.get('/', protect, listMatches);
router.post('/', protect, createMatch);

module.exports = router;
