// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IConditional.sol';

contract MTGYRaffle {
  function getRaffleEntries(bytes32 _id) external view returns (address[] memory) {}
}

contract HasRaffleEntry is IConditional, Ownable {
  address public raffleContract;
  bytes32 public raffleId;
  uint256 public minRaffleEntries = 1;

  constructor(address _raffleContract, bytes32 _raffleId) {
    raffleContract = _raffleContract;
    raffleId = _raffleId;
  }

  function passesTest(address wallet) external view override returns (bool) {
    address[] memory _entries = MTGYRaffle(raffleContract).getRaffleEntries(raffleId);
    uint counts = 0;

    for (uint256 _i = 0; _i < _entries.length; _i++) {
      if(_entries[_i] == wallet){
        counts++;
      }
    }

    return counts >= minRaffleEntries;
  }

  function setRaffleContract(address _raffleContract) external onlyOwner {
    raffleContract = _raffleContract;
  }

  function setRaffleId(bytes32 _raffleId) external onlyOwner {
    raffleId = _raffleId;
  }

  function setMinRaffleEntries(uint256 _newMin) external onlyOwner {
    minRaffleEntries = _newMin;
  }
}
