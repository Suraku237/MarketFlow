const { Router } = require('express');
const { authenticate, authorize } = require('../auth/middleware');
const { listProducts, getProductById, createProduct } = require('../store');

const router = Router();

router.get('/', authenticate, async (req, res) => {
  const products = await listProducts();
  res.json({ service: 'inventory-service', products });
});

router.get('/:id', authenticate, async (req, res) => {
  const product = await getProductById(req.params.id);
  if (!product) {
    return res.status(404).json({ error: 'product not found' });
  }
  res.json({ service: 'inventory-service', product });
});

router.post('/', authenticate, authorize('admin'), async (req, res) => {
  const { sku, name, categoryId, supplierId, unitPrice, quantityInStock, reorderLevel } = req.body || {};

  if (!sku || !name || !categoryId || unitPrice === undefined) {
    return res.status(400).json({ error: 'sku, name, categoryId and unitPrice are required' });
  }

  try {
    const product = await createProduct({ sku, name, categoryId, supplierId, unitPrice, quantityInStock, reorderLevel });
    res.status(201).json({ service: 'inventory-service', product });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'a product with this sku already exists' });
    }
    throw err;
  }
});

module.exports = router;
