# EntropyViewWithEncrypted

Learn how to encrypt a single value using FHE.fromExternal

## 🎓 What You'll Learn

This example teaches you how to use FHEVM to build privacy-preserving smart contracts. You'll learn step-by-step how to implement encrypted operations, manage permissions, and work with encrypted data.

## 🚀 Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/zacnider/fhevm-example-anti-patterns-viewwithencrypted.git
   cd fhevm-example-anti-patterns-viewwithencrypted
   ```

2. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

3. **Setup environment:**
   ```bash
   npm run setup
   ```
   Then edit `.env` file with your credentials:
   - `SEPOLIA_RPC_URL` - Your Sepolia RPC endpoint
   - `PRIVATE_KEY` - Your wallet private key (for deployment)
   - `ETHERSCAN_API_KEY` - Your Etherscan API key (for verification)

4. **Compile contracts:**
   ```bash
   npm run compile
   ```

5. **Run tests:**
   ```bash
   npm test
   ```

6. **Deploy to Sepolia:**
   ```bash
   npm run deploy:sepolia
   ```

7. **Verify contract (after deployment):**
   ```bash
   npm run verify <CONTRACT_ADDRESS>
   ```

**Alternative:** Use the [Examples page](https://entrofhe.vercel.app/examples) for browser-based deployment and verification.

---

## 📚 Overview

This example teaches you how to use FHEVM to build privacy-preserving smart contracts.

@title EntropyViewWithEncrypted
@notice View functions with encrypted values and encrypted randomness (not allowed)
@dev ANTI-PATTERN: This demonstrates what NOT to do with encrypted randomness
⚠️ ANTI-PATTERN WARNING:
View functions cannot return encrypted values (euint64) directly.
FHE operations are considered state-modifying, so they cannot be in view functions.
encrypted randomness operations also cannot be in view functions.
Common Mistakes:
1. Trying to return euint64 from view functions
2. Using FHE operations in view functions
3. Trying to get entropy from encrypted randomness in view functions
4. Expecting encrypted values to work in pure/view contexts
Correct Approach:
- Use regular functions (not view) to return encrypted values
- Or return the encrypted value handle as bytes/string
- Or use events to emit encrypted values

@notice Constructor - sets encrypted randomness address
@param _encrypted randomness Address of encrypted randomness contract

@notice Request entropy
@param tag Unique tag for this request
@return requestId Request ID from encrypted randomness

@notice Initialize encrypted value
@param encryptedInput Encrypted value
@param inputProof Input proof

❌ ANTI-PATTERN: View function returning encrypted value
@dev This will NOT compile - view functions cannot return euint64
@dev FHE operations are state-modifying, so they can't be in view functions
Error you'll get:
"Function cannot be declared as view because this expression (potentially) modifies the state."

✅ CORRECT: Regular function (not view) to return encrypted value
@return Encrypted value

❌ ANTI-PATTERN: View function trying to get entropy
@dev This will NOT compile - view functions cannot call encrypted randomness

✅ ALTERNATIVE: Return as bytes (if you need view-like behavior)
@dev You can return the handle as bytes, but this loses FHE capabilities

@notice Get encrypted randomness address



## 🔐 Learn Zama FHEVM Through This Example

This example teaches you how to use the following **Zama FHEVM** features:

### What You'll Learn About

- **ZamaEthereumConfig**: Inherits from Zama's network configuration
  ```solidity
  contract MyContract is ZamaEthereumConfig {
      // Inherits network-specific FHEVM configuration
  }
  ```

- **FHE Operations**: Uses Zama's FHE library for encrypted operations
  - `FHE.add()` - Zama FHEVM operation
  - `FHE.sub()` - Zama FHEVM operation
  - `FHE.mul()` - Zama FHEVM operation
  - `FHE.eq()` - Zama FHEVM operation
  - `FHE.xor()` - Zama FHEVM operation

- **Encrypted Types**: Uses Zama's encrypted integer types
  - `euint64` - 64-bit encrypted unsigned integer
  - `externalEuint64` - External encrypted value from user

- **Access Control**: Uses Zama's permission system
  - `FHE.allowThis()` - Allow contract to use encrypted values
  - `FHE.allow()` - Allow specific user to decrypt
  - `FHE.allowTransient()` - Temporary permission for single operation
  - `FHE.fromExternal()` - Convert external encrypted values to internal

### Zama FHEVM Imports

```solidity
// Zama FHEVM Core Library - FHE operations and encrypted types
import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";

// Zama Network Configuration - Provides network-specific settings
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
```

### Zama FHEVM Code Example

```solidity
// Using Zama FHEVM's encrypted integer type
euint64 private encryptedValue;

// Converting external encrypted value to internal (Zama FHEVM)
euint64 internalValue = FHE.fromExternal(encryptedValue, inputProof);
FHE.allowThis(internalValue); // Zama FHEVM permission system

// Performing encrypted operations using Zama FHEVM
euint64 result = FHE.add(encryptedValue, FHE.asEuint64(1));
FHE.allowThis(result);
```

### FHEVM Concepts You'll Learn

1. **Encrypted Arithmetic**: Learn how to use Zama FHEVM for encrypted arithmetic
2. **Encrypted Comparison**: Learn how to use Zama FHEVM for encrypted comparison
3. **External Encryption**: Learn how to use Zama FHEVM for external encryption
4. **Permission Management**: Learn how to use Zama FHEVM for permission management
5. **Entropy Integration**: Learn how to use Zama FHEVM for entropy integration

### Learn More About Zama FHEVM

- 📚 [Zama FHEVM Documentation](https://docs.zama.org/protocol)
- 🎓 [Zama Developer Hub](https://www.zama.org/developer-hub)
- 💻 [Zama FHEVM GitHub](https://github.com/zama-ai/fhevm)



## 🔍 Contract Code

```solidity
// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.27;

import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import "./IEntropyOracle.sol";

/**
 * @title EntropyViewWithEncrypted
 * @notice View functions with encrypted values and EntropyOracle (not allowed)
 * @dev ANTI-PATTERN: This demonstrates what NOT to do with EntropyOracle
 * 
 * ⚠️ ANTI-PATTERN WARNING:
 * 
 * View functions cannot return encrypted values (euint64) directly.
 * FHE operations are considered state-modifying, so they cannot be in view functions.
 * EntropyOracle operations also cannot be in view functions.
 * 
 * Common Mistakes:
 * 1. Trying to return euint64 from view functions
 * 2. Using FHE operations in view functions
 * 3. Trying to get entropy from EntropyOracle in view functions
 * 4. Expecting encrypted values to work in pure/view contexts
 * 
 * Correct Approach:
 * - Use regular functions (not view) to return encrypted values
 * - Or return the encrypted value handle as bytes/string
 * - Or use events to emit encrypted values
 */
contract EntropyViewWithEncrypted is ZamaEthereumConfig {
    // Entropy Oracle interface
    IEntropyOracle public entropyOracle;
    
    euint64 private encryptedValue;
    bool private initialized;
    
    // Track entropy requests
    mapping(uint256 => bool) public entropyRequests;
    
    event EntropyRequested(uint256 indexed requestId, address indexed caller);
    
    /**
     * @notice Constructor - sets EntropyOracle address
     * @param _entropyOracle Address of EntropyOracle contract
     */
    constructor(address _entropyOracle) {
        require(_entropyOracle != address(0), "Invalid oracle address");
        entropyOracle = IEntropyOracle(_entropyOracle);
    }
    
    /**
     * @notice Request entropy
     * @param tag Unique tag for this request
     * @return requestId Request ID from EntropyOracle
     */
    function requestEntropy(bytes32 tag) external payable returns (uint256 requestId) {
        require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
        requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
        entropyRequests[requestId] = true;
        emit EntropyRequested(requestId, msg.sender);
        return requestId;
    }
    
    /**
     * @notice Initialize encrypted value
     * @param encryptedInput Encrypted value
     * @param inputProof Input proof
     */
    function initialize(
        externalEuint64 encryptedInput,
        bytes calldata inputProof
    ) external {
        require(!initialized, "Already initialized");
        
        euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
        FHE.allowThis(internalValue);
        
        encryptedValue = internalValue;
        initialized = true;
    }
    
    /**
     * ❌ ANTI-PATTERN: View function returning encrypted value
     * @dev This will NOT compile - view functions cannot return euint64
     * @dev FHE operations are state-modifying, so they can't be in view functions
     * 
     * Error you'll get:
     * "Function cannot be declared as view because this expression (potentially) modifies the state."
     */
    // function getValue() external view returns (euint64) {
    //     return encryptedValue; // ❌ This won't work!
    // }
    
    /**
     * ✅ CORRECT: Regular function (not view) to return encrypted value
     * @return Encrypted value
     */
    function getValue() external returns (euint64) {
        require(initialized, "Not initialized");
        return encryptedValue; // ✅ This works!
    }
    
    /**
     * ❌ ANTI-PATTERN: View function trying to get entropy
     * @dev This will NOT compile - view functions cannot call EntropyOracle
     */
    // function getEntropyInView(uint256 requestId) external view returns (euint64) {
    //     // ❌ This won't work! EntropyOracle.getEncryptedEntropy() is not view
    //     return entropyOracle.getEncryptedEntropy(requestId);
    // }
    
    /**
     * ✅ ALTERNATIVE: Return as bytes (if you need view-like behavior)
     * @dev You can return the handle as bytes, but this loses FHE capabilities
     */
    // function getValueAsBytes() external view returns (bytes memory) {
    //     // Convert handle to bytes (loses FHE capabilities)
    //     // This is a workaround, but not recommended
    // }
    
    /**
     * @notice Get EntropyOracle address
     */
    function getEntropyOracle() external view returns (address) {
        return address(entropyOracle);
    }
}

```

## 🧪 Tests

See [test file](./test/EntropyViewWithEncrypted.test.ts) for comprehensive test coverage.

```bash
npm test
```


## 📚 Category

**anti**



## 🔗 Related Examples

- [All anti examples](https://github.com/zacnider/entrofhe/tree/main/examples)

## 📝 License

BSD-3-Clause-Clear
