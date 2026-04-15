# Fix Proposal: VectorStoreFactory.create() TypeError

## Problem
`TypeError: Cannot read property 'name' of undefined` when calling `VectorStoreFactory.create()` from `pipeline/phase2.py`.

## Root Cause
The `VectorStoreFactory.create()` method signature was changed to take NO parameters:
```python
def create(cls) -> Any:  # No parameters
```

But `pipeline/phase2.py` still calls it with a provider argument:
```python
VectorStoreFactory.create("milvus")  # Line 418
VectorStoreFactory.create("milvus")  # Line 446
```

## Fix

### Option A: Fix the Callers (Recommended)

Remove the `"milvus"` argument from both call sites in `pipeline/phase2.py`:

**Line 418:**
```python
# Before:
vector_store = VectorStoreFactory.create("milvus")
# After:
vector_store = VectorStoreFactory.create()
```

**Line 446:**
```python
# Before:
vector_store = VectorStoreFactory.create("milvus")
# After:
vector_store = VectorStoreFactory.create()
```

The provider is determined by `VECTOR_STORE_PROVIDER` environment variable or `get_settings().vector_store.provider`.

### Option B: Restore the create() Signature

If explicit provider override is needed, restore the signature:

```python
def create(cls, provider: str = None, config: Dict = None) -> Any:
    if provider is None:
        vector_store_config = get_settings().vector_store
        # ... rest of config loading
    else:
        # Use explicitly provided provider/config
```

This is a larger change and affects the design intent.

## Files to Modify

| File | Line | Change |
|------|------|--------|
| `pipeline/phase2.py` | 418 | `VectorStoreFactory.create("milvus")` -> `VectorStoreFactory.create()` |
| `pipeline/phase2.py` | 446 | `VectorStoreFactory.create("milvus")` -> `VectorStoreFactory.create()` |

## Verification
After fix:
1. Ensure `VECTOR_STORE_PROVIDER=milvus` is set in `.env`
2. Run the application - error should not occur
3. Vector store should initialize correctly using Milvus provider
