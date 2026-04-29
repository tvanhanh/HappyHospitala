// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract MedicalRecords {
    struct Record {
        string patientId;
        string ipfsHash;
        string dob;
        string data;
        uint256 timestamp;
    }

    mapping(string => Record[]) private recordsByPatient;

    event RecordAdded(string indexed patientId, uint256 index);

    function addRecord(string memory patientId, string memory ipfsHash, string memory dob, string memory data) public {
        recordsByPatient[patientId].push(Record(patientId, ipfsHash, dob, data, block.timestamp));
        emit RecordAdded(patientId, recordsByPatient[patientId].length - 1);
    }

    function getRecordCount(string memory patientId) public view returns (uint256) {
        return recordsByPatient[patientId].length;
    }

    function getRecord(string memory patientId, uint256 index) public view returns (string memory, string memory, string memory, string memory, uint256) {
        require(index < recordsByPatient[patientId].length, "Invalid index");
        Record memory rec = recordsByPatient[patientId][index];
        return (rec.patientId, rec.ipfsHash, rec.dob, rec.data, rec.timestamp);
    }
}
