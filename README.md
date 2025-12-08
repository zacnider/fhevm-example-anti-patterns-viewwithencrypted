# EntropyViewWithEncrypted

View functions with encrypted values and EntropyOracle (ANTI-PATTERN)

## 🚀 Standard workflow
- Install (first run): `npm install --legacy-peer-deps`
- Compile: `npx hardhat compile`
- Test (local FHE + local oracle/chaos engine auto-deployed): `npx hardhat test`
- Deploy (frontend Deploy button): constructor arg is fixed to EntropyOracle `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
- Verify: `npx hardhat verify --network sepolia <contractAddress> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

## 📋 Overview

This example demonstrates **anti-patterns** in FHEVM with **EntropyOracle integration**:
- View functions cannot return encrypted values
- View functions cannot call EntropyOracle
- FHE operations are state-modifying
- Correct approaches for returning encrypted values

## 🎯 What This Example Teaches

This tutorial will teach you:

1. **Why view/pure functions can't use FHE** operations
2. **Limitations of view functions** with encrypted values
3. **How to work around this** limitation
4. **Why FHE operations are state-modifying** (symbolic execution)
5. **Alternative approaches** for view-like behavior
6. **EntropyOracle limitations** in view functions

## 💡 Why This Matters

Understanding limitations prevents errors:
- **Saves debugging time**: Know what won't work
- **Prevents compilation errors**: Understand why view functions fail
- **Shows correct patterns**: Learn workarounds
- **FHE operations modify state** symbolically, so they can't be view

## 🔍 How It Works

### Contract Structure

The contract demonstrates both WRONG and CORRECT patterns:

1. **Wrong Pattern**: View function returning `euint64` - will NOT compile
2. **Correct Pattern**: Regular function (not view) returning `euint64` - will work
3. **Wrong Pattern**: View function calling EntropyOracle - will NOT compile
4. **Correct Pattern**: Regular function calling EntropyOracle - will work

### Step-by-Step Code Explanation

#### 1. Constructor

```solidity
constructor(address _entropyOracle) {
    require(_entropyOracle != address(0), "Invalid oracle address");
    entropyOracle = IEntropyOracle(_entropyOracle);
}
```

**What it does:**
- Takes EntropyOracle address as parameter
- Validates the address is not zero
- Stores the oracle interface

#### 2. Initialize

```solidity
function initialize(
    externalEuint64 encryptedInput,
    bytes calldata inputProof
) external {
    euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
    FHE.allowThis(internalValue);
    encryptedValue = internalValue;
    initialized = true;
}
```

**What it does:**
- Accepts encrypted value from external source
- Validates encrypted value using input proof
- Converts to internal format
- Grants permission to use value
- Stores encrypted value

#### 3. ❌ WRONG: View Function Returning euint64

```solidity
// ❌ This will NOT compile!
// function getValue() external view returns (euint64) {
//     return encryptedValue; // Error: Function cannot be declared as view
// }
```

**What it does:**
- Attempts to return `euint64` from view function
- **Will NOT compile** - compilation error

**Why it fails:**
- FHE operations are considered state-modifying
- View functions cannot modify state
- `euint64` return type requires FHE operations
- Compiler error: "Function cannot be declared as view because this expression (potentially) modifies the state."

#### 4. ✅ CORRECT: Regular Function (Not View)

```solidity
function getValue() external returns (euint64) {
    require(initialized, "Not initialized");
    return encryptedValue; // ✅ This works!
}
```

**What it does:**
- Returns `euint64` from regular function (not view)
- **Will compile and work** correctly

**Why it works:**
- Regular functions can modify state
- FHE operations are allowed in regular functions
- No view modifier = no restrictions

#### 5. ❌ WRONG: View Function Calling EntropyOracle

```solidity
// ❌ This will NOT compile!
// function getEntropyInView(uint256 requestId) external view returns (euint64) {
//     return entropyOracle.getEncryptedEntropy(requestId); // Error: Not view
// }
```

**What it does:**
- Attempts to call EntropyOracle from view function
- **Will NOT compile** - compilation error

**Why it fails:**
- `entropyOracle.getEncryptedEntropy()` is not a view function
- It performs FHE operations (state-modifying)
- View functions cannot call non-view functions
- Compiler error: "Function cannot be declared as view"

#### 6. ✅ CORRECT: Regular Function Calling EntropyOracle

```solidity
function requestEntropy(bytes32 tag) external payable returns (uint256 requestId) {
    require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
    requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
    entropyRequests[requestId] = true;
    return requestId;
}
```

**What it does:**
- Calls EntropyOracle from regular function
- **Will compile and work** correctly

**Why it works:**
- Regular functions can call other functions
- No view modifier = no restrictions

## 🧪 Step-by-Step Testing

### Prerequisites

1. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

2. **Compile contracts:**
   ```bash
   npx hardhat compile
   ```

### Running Tests

```bash
npx hardhat test
```

### What Happens in Tests

1. **Fixture Setup** (`deployContractFixture`):
   - Deploys FHEChaosEngine, EntropyOracle, and EntropyViewWithEncrypted
   - Returns all contract instances

2. **Test: Initialize**
   ```typescript
   it("Should initialize with encrypted value", async function () {
     const input = hre.fhevm.createEncryptedInput(contractAddress, owner.address);
     input.add64(42);
     const encryptedInput = await input.encrypt();
     
     await contract.initialize(encryptedInput.handles[0], encryptedInput.inputProof);
     
     expect(await contract.isInitialized()).to.be.true;
   });
   ```
   - Creates encrypted input (value: 42)
   - Encrypts using FHEVM SDK
   - Calls `initialize()` with handle and proof

3. **Test: Get Value (Regular Function)**
   ```typescript
   it("Should get value using regular function", async function () {
     // ... initialization code ...
     const value = await contract.getValue(); // ✅ Works (not view)
     expect(value).to.not.be.undefined;
   });
   ```
   - Calls `getValue()` (regular function, not view)
   - **Works** correctly
   - Returns encrypted value

### Expected Test Output

```
  EntropyViewWithEncrypted
    Deployment
      ✓ Should deploy successfully
      ✓ Should have EntropyOracle address set
    Initialization
      ✓ Should initialize with encrypted value
    Value Retrieval
      ✓ Should get value using regular function (not view)
      ✓ Should demonstrate view function limitations

  5 passing
```

**Note:** View functions cannot return `euint64` or call EntropyOracle. Use regular functions instead.

## 🚀 Step-by-Step Deployment

### Option 1: Frontend (Recommended)

1. Navigate to [Examples page](/examples)
2. Find "EntropyViewWithEncrypted" in Tutorial Examples
3. Click **"Deploy"** button
4. Approve transaction in wallet
5. Wait for deployment confirmation
6. Copy deployed contract address

### Option 2: CLI

1. **Create deploy script** (`scripts/deploy.ts`):
   ```typescript
   import hre from "hardhat";

   async function main() {
     const ENTROPY_ORACLE_ADDRESS = "0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361";
     
     const ContractFactory = await hre.ethers.getContractFactory("EntropyViewWithEncrypted");
     const contract = await ContractFactory.deploy(ENTROPY_ORACLE_ADDRESS);
     await contract.waitForDeployment();
     
     const address = await contract.getAddress();
     console.log("EntropyViewWithEncrypted deployed to:", address);
   }

   main().catch((error) => {
     console.error(error);
     process.exitCode = 1;
   });
   ```

2. **Deploy:**
   ```bash
   npx hardhat run scripts/deploy.ts --network sepolia
   ```

## ✅ Step-by-Step Verification

### Option 1: Frontend

1. After deployment, click **"Verify"** button on Examples page
2. Wait for verification confirmation
3. View verified contract on Etherscan

### Option 2: CLI

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361
```

**Important:** Constructor argument must be the EntropyOracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

## 📊 Expected Outputs

### After Initialize

- `isInitialized()` returns `true`
- Value stored but cannot be retrieved via view function

### After Get Value (Regular Function)

- `getValue()` returns encrypted value (handle)
- **Works** because it's not a view function
- Can be called from frontend or other contracts

## ⚠️ Common Errors & Solutions

### Error: `Function cannot be declared as view`

**Cause:** Trying to return `euint64` from view function or use FHE operations in view function.

**Example:**
```solidity
// ❌ This will NOT compile!
function getValue() external view returns (euint64) {
    return encryptedValue; // Error: view functions can't return euint64
}
```

**Solution:**
```solidity
// ✅ Remove 'view' modifier
function getValue() external returns (euint64) {
    return encryptedValue; // ✅ Works!
}
```

**Prevention:** Never use `view` or `pure` modifiers with functions that:
- Return `euint64`
- Use FHE operations
- Call EntropyOracle
- Perform any FHE-related operations

---

### Error: `Function cannot be declared as pure`

**Cause:** Trying to use FHE operations in pure function.

**Solution:** Remove `pure` modifier. FHE operations require state access.

---

### Error: `EntropyOracle.getEncryptedEntropy() is not view`

**Cause:** Trying to call EntropyOracle from view function.

**Solution:** Use regular function (not view) to call EntropyOracle.

---

### Error: `Insufficient fee`

**Cause:** Not sending enough ETH when requesting entropy.

**Solution:** Always send exactly 0.00001 ETH:
```typescript
const fee = await contract.entropyOracle.getFee();
await contract.requestEntropy(tag, { value: fee });
```

---

### Error: Verification failed - Constructor arguments mismatch

**Cause:** Wrong constructor argument used during verification.

**Solution:** Always use the EntropyOracle address:
```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361
```

## 🔗 Related Examples

- [EntropyMissingAllowThis](../anti-patterns-missingallowthis/) - Missing allowThis
- [EntropyCounter](../basic-simplecounter/) - Correct usage example
- [Category: anti-patterns](../)

## 📚 Additional Resources

- [Full Tutorial Track Documentation](../../../frontend/src/pages/Docs.tsx) - Complete educational guide
- [Zama FHEVM Documentation](https://docs.zama.org/) - Official FHEVM docs
- [GitHub Repository](https://github.com/zacnider/entrofhe/tree/main/examples/anti-patterns-viewwithencrypted) - Source code

## 📝 License

BSD-3-Clause-Clear
