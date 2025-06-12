// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract SupplyChainAsset {
    struct Origin {
        string country;
        string state;
        string city;
    }

    struct CostDetails {
        uint256 baseCost;
        string currency;
    }

    struct Verification {
        bool isCertified;
        string certificationBody;
        string inspectionDate;
        bool isTamperEvident;
    }

    struct StorageRequirements {
        bool requiresColdChain;
        string temperatureRange;
        string humidityLevel;
    }

    struct KeyValue {
    		string key;
    		string value;
    }

    struct Stage {
        uint256 stageNumber;
        string stageName;
        string sentBy;
        string timestamp;
        Origin location;
        KeyValue[] transactionData; 
    }

    struct Transaction {
        string transactionId;
        string transactionDate;
        string transactionType;
        string transactionOwner;
        string transactionNotes;
        uint256 parentTxnIndex; // 0 for T0
        Stage[] stages;
    }

    struct Asset {
        string assetId;
        string assetName;
        string assetType;
        string createdBy;
        string currentOwner;
        string manufactureDate;
        string expiryDate;
        string unit;
        uint256 quantity;
        Origin origin;
        CostDetails costDetails;
        Verification verified;
        StorageRequirements storageRequirements;
        string status;
        string[] tags;
        string additionalNotes;
        bool exists;
    }

    mapping(string => Asset) public assets; // assetId => Asset
    mapping(string => Transaction[]) public transactions; 
    // assetId => Transactions list

    // ========== Asset Methods ==========

    function addAsset(
        string memory _assetId,  // _assetId is a state variable
        string memory _assetName,
        string memory _assetType,
        string memory _createdBy,
        string memory _currentOwner,
        string memory _manufactureDate,
        string memory _expiryDate,
        string memory _unit,
        uint256 _quantity,
        string memory _country,
        string memory _state,
        string memory _city,
        uint256 _baseCost,
        string memory _currency,
        bool _isCertified,
        string memory _certificationBody,
        string memory _inspectionDate,
        bool _isTamperEvident,
        bool _requiresColdChain,
        string memory _temperatureRange,
        string memory _humidityLevel,
        string memory _status,
        string[] memory _tags,
        string memory _additionalNotes
    ) public {
        require(!assets[_assetId].exists, "Asset already exists"); // it reverts the message only if the condition is false
        Origin memory origin = Origin(_country, _state, _city);
        CostDetails memory cost = CostDetails(_baseCost, _currency);
        Verification memory verify = Verification(_isCertified,
        _certificationBody, _inspectionDate, _isTamperEvident);
        StorageRequirements memory storageReq = StorageRequirements(_requiresColdChain, _temperatureRange, _humidityLevel);

        assets[_assetId] = Asset({ // new Asset record is permanently saved to the blockchain
            assetId: _assetId,
            assetName: _assetName,
            assetType: _assetType,
            createdBy: _createdBy,
            currentOwner: _currentOwner,
            manufactureDate: _manufactureDate,
            expiryDate: _expiryDate,
            unit: _unit,
            quantity: _quantity,
            origin: origin,
            costDetails: cost,
            verified: verify,
            storageRequirements: storageReq,
            status: _status,
            tags: _tags,
            additionalNotes: _additionalNotes,
            exists: true
        });
    }

    // ========== Transaction Methods ==========

    function addRootTransaction(   // add the very first transaction T0
        string memory _assetId,
        string memory _transactionId,
        string memory _transactionDate,
        string memory _transactionType,
        string memory _transactionOwner,
        string memory _transactionNotes
    ) public {
        require(assets[_assetId].exists, "Asset does not exist"); // it reverts the message only if the condition is false
        require(transactions[_assetId].length == 0, "Root transaction already exists");

        Transaction storage txn = transactions[_assetId].push();
        txn.transactionId = _transactionId;
        txn.transactionDate = _transactionDate;
        txn.transactionType = _transactionType;
        txn.transactionOwner = _transactionOwner;
        txn.transactionNotes = _transactionNotes;
        txn.parentTxnIndex = 0; // root transaction has no parent
    }

    function addChildTransaction(
        string memory _assetId,
        string memory _transactionId,
        string memory _transactionDate,
        string memory _transactionType,
        string memory _transactionOwner,
        string memory _transactionNotes,
        uint256 _parentTxnIndex
    ) public {
        require(assets[_assetId].exists, "Asset does not exist");
        require(_parentTxnIndex < transactions[_assetId].length, "Parent transaction doesn't exist");

        Transaction storage txn = transactions[_assetId].push();
        txn.transactionId = _transactionId;
        txn.transactionDate = _transactionDate;
        txn.transactionType = _transactionType;
        txn.transactionOwner = _transactionOwner;
        txn.transactionNotes = _transactionNotes;
        txn.parentTxnIndex = _parentTxnIndex;
    }

    function addStageToTransaction(
    string memory _assetId,
    uint256 _txnIndex,
    uint256 _stageNumber,
    string memory _stageName,
    string memory _sentBy,
    string memory _timestamp,
    string memory _country,
    string memory _state,
    string memory _city,
    string[] memory _keys,
    string[] memory _values
    ) public {
    require(assets[_assetId].exists, "Asset does not exist");
    require(_txnIndex < transactions[_assetId].length, "Transaction does not exist");
    require(_keys.length == _values.length, "Keys and values length mismatch");

    Stage memory newStage;
    newStage.stageNumber = _stageNumber;
    newStage.stageName = _stageName;
    newStage.sentBy = _sentBy;
    newStage.timestamp = _timestamp;
    newStage.location = Origin(_country, _state, _city);

    // ✅ Allocate memory for transactionData
    newStage.transactionData = new KeyValue[](_keys.length);

    for (uint i = 0; i < _keys.length; i++) {
        newStage.transactionData[i] = KeyValue({
            key: _keys[i],
            value: _values[i]
        });
    }

    // ✅ Push to storage array
    transactions[_assetId][_txnIndex].stages.push(newStage);
    }

    function getTransactionCount(string memory _assetId) public view returns (uint256) {
        return transactions[_assetId].length;
    }

    function getTransactionByIndex(string memory _assetId, uint256 index)
    public 
    view 
    returns (
        string memory, 
        string memory,
        string memory,
        string memory,
        string memory, 
        uint256
        ) 
    {
        Transaction storage txn = transactions[_assetId][index];
        return (
            txn.transactionId,
            txn.transactionDate,
            txn.transactionType,
            txn.transactionOwner,
            txn.transactionNotes,
            txn.parentTxnIndex
        );
    }

    function getAsset(string memory _assetId) public view returns (Asset memory) {
        return assets[_assetId];
    }

    function getFullAssetDetails(string memory _assetId) 
        public 
        view 
        returns (
            Asset memory,
            Transaction[] memory
        ) 
    {
        require(assets[_assetId].exists, "Asset does not exist");
        return (
            assets[_assetId],
            transactions[_assetId]
        );
    }
}
