// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './MTGY.sol';
import './MTGYSpend.sol';

/**
 * @title MTGYPolling
 * @dev Logic for storing and retrieving poll information from the blockchain.
 */
contract MTGYPolling is Ownable {
  using SafeMath for uint256;

  MTGY private _mtgy;
  MTGYSpend private _mtgySpend;

  address public mtgyTokenAddy;
  address public mtgySpendAddy;
  uint256 public mtgyServiceCost = 100 * 10**18;
  
  // Poll option struct
  struct PollOption {
    string id; // id for ref
    string text; // poll option text
    bool isDeleted;
  }

  // Poll struct
  struct Poll {
    string id; // id for ref
    string text; // poll text
    uint256 createdAt; // unix timestamp of when this poll was created
    uint256 closesAt; // unix timestamp of when this poll will close
    bool isDeleted;

    mapping(string => PollOption[]) pollOptions; // mapping of poll options
  }

  // mapping of all polls owned by a user
  mapping(address => Poll[]) public userPolls;

  constructor(address _mtgyTokenAddy, address _mtgySpendAddy) {
    mtgyTokenAddy = _mtgyTokenAddy;
    mtgySpendAddy = _mtgySpendAddy;
    _mtgy = MTGY(_mtgyTokenAddy);
    _mtgySpend = MTGYSpend(_mtgySpendAddy);
  }

  function changeMtgyTokenAddy(address _tokenAddy) external onlyOwner {
    mtgyTokenAddy = _tokenAddy;
    _mtgy = MTGY(_tokenAddy);
  }

  function changeMtgySpendAddy(address _spendAddy) external onlyOwner {
    mtgySpendAddy = _spendAddy;
    _mtgySpend = MTGYSpend(_spendAddy);
  }

  function changeServiceCost(uint256 _newCost) external onlyOwner {
    mtgyServiceCost = _newCost;
  }


  //-- Polls --//
  function getAllPolls(address _userAddy)
    external
    view
    returns (Poll[] memory)
  {
    return Poll[_userAddy];
  }

  function getPollById(string memory _id)
    external
    view
    returns (Poll memory)
  {
    // User polls
    Poll[] memory _userPolls = userPolls[msg.sender];

    // Lopp over user polls to find specific poll
    for (uint256 _i = 0; _i < _userPolls.length; _i++) {
      if (_compareStr(_userPolls[_i].id, _id)) {
        return _userPolls[_i];
      }
    }

    // If no poll found, return empty poll
    return
      Poll({
        id: '',
        text: '',
        createdAt: 0,
        closesAt: 0,
        isDeleted: false,
        pollOptions: []
      });
  }

  function createPoll(
    string memory _id,
    string memory _text,
    uint256 memory _closesAt
  ) external {
    _mtgy.transferFrom(msg.sender, address(this), mtgyServiceCost);
    _mtgy.approve(mtgySpendAddy, mtgyServiceCost);
    _mtgySpend.spendOnProduct(mtgyServiceCost);

    userPolls[msg.sender].push(
      Poll({
        id: _id,
        text: _text,
        createdAt: block.timestamp,
        closesAt: _closesAt,
        isDeleted: false
      })
    );
  }

  function deletePoll(string memory _id) external returns (bool) {
    // User polls
    Poll[] memory _userPolls = userPolls[msg.sender];
    
    // Lopp over user polls to find specific poll
    for (uint256 _i = 0; _i < _userPolls.length; _i++) {
      if (_compareStr(_userPolls[_i].id, _id)) {
        
        // Set specific poll as 'deleted'
        userPolls[msg.sender][_i].isDeleted = true;
        return true;
      }
    }
    return false;
  }

  //-- Poll Options --//
  function createPollOption(
    string memory _pollId, 
    string memory _optionId, 
    string memory _optionText
  ) external {
    // User polls
    Poll[] memory _userPolls = userPolls[msg.sender];

    // Lopp over user polls to find specific poll
    for (uint256 _i = 0; _i < _userPolls.length; _i++) {
      if (_compareStr(_userPolls[_i].id, _pollId)) {
        
        // Push new poll options to specific poll
        userPolls[msg.sender].pollOptions.push(
          PollOption({
            id: _optionId,
            text: _optionText,
            isDeleted: false
          })
        );
      }
    }
  }

  function deletePollOption(
    string memory _pollId, 
    string memory _optionId
  ) external returns (bool) {
    // User polls
    Poll[] memory _userPolls = userPolls[msg.sender];
    
    // Lopp over user polls to find specific poll
    for (uint256 _i = 0; _i < _userPolls.length; _i++) {
      if (_compareStr(_userPolls[_i].id, _pollId)) {
        
        // Poll options
        PollOptions[] memory _pollOptions = _userPolls[_i].pollOptions;
        
        // Lopp over poll options to find specific poll option
        for (uint256 _j = 0; _j < _pollOptions.length; _j++) {
          if (_compareStr(_pollOptions[_j].id, _optionId)) {

            // Set poll option as 'deleted'
            userPolls[msg.sender].pollOptions[_j].isDeleted = true;
            return true;
          }
        }

      }
    }
    return false;
  }


  function _compareStr(string memory a, string memory b)
    private
    pure
    returns (bool)
  {
    return (keccak256(abi.encodePacked((a))) ==
      keccak256(abi.encodePacked((b))));
  }
}
