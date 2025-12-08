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
