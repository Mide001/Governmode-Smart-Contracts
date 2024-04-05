// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GovernMode {
    address private _admin;
    uint256 private proposalCount;

    enum ProposalStatus {
        Pending,
        Approved,
        Rejected
    }
    
    struct Proposal {
        uint256 id;
        string title;
        string content;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        ProposalStatus status;
        address creator;
    }

    struct Member {
        uint256 proposalsCreated;
        uint256 proposalsParticipatedIn;
        bool voted;
    }

    mapping(uint256 => Proposal) private _proposals;
    mapping(address => Member) private _members;
    mapping(uint256 => mapping(address => bool)) private _hasVoted;

    event ProposalCreated(
        uint256 indexed id,
        string title,
        string content,
        uint256 startTime,
        uint256 endTime,
        address indexed creator
    );

    event Voted(
        uint256 indexed proposalId,
        address indexed member,
        bool support
    );

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Not authorized");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(
            _proposalId > 0 && _proposalId <= proposalCount,
            "Invalid proposal ID"
        );
        _;
    }

    constructor() {
        _admin = msg.sender;
    }

    function createProposal(
        string memory _title,
        string memory _content,
        uint256 _durationInDays 
    ) external {
        proposalCount++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + (_durationInDays * 1 days); 

        _proposals[proposalCount] = Proposal({
            id: proposalCount,
            title: _title,
            content: _content,
            forVotes: 0,
            againstVotes: 0,
            startTime: startTime,
            endTime: endTime,
            status: ProposalStatus.Pending,
            creator: msg.sender
        });

        _members[msg.sender].proposalsCreated++;

        emit ProposalCreated(proposalCount, _title, _content, startTime, endTime, msg.sender);
    }

    function vote(
        uint256 _proposalId,
        bool _support
    ) external validProposal(_proposalId) {
        Proposal storage proposal = _proposals[_proposalId];
        require(
            block.timestamp >= proposal.startTime &&
                block.timestamp <= proposal.endTime,
            "Voting is closed!"
        );
        require(!_hasVoted[_proposalId][msg.sender], "Already Voted!");

        if (_support) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }

        _hasVoted[_proposalId][msg.sender] = true;
        _members[msg.sender].proposalsParticipatedIn++;

        emit Voted(_proposalId, msg.sender, _support);
    }

    function getAllProposals() external view returns (Proposal[] memory) {
        Proposal[] memory proposalsList = new Proposal[](proposalCount);
        for (uint256 i = 1; i <= proposalCount; i++) {
            proposalsList[i - 1] = _proposals[i];
        }
        return proposalsList;
    }

    function revealAdmin() public view returns (address) {
        return _admin;
    }

    function getTotalNoOfProposals() public view returns (uint256) {
        return proposalCount;
    }

    function getProposalDetails(
        uint256 _proposalId
    )
        external
        view
        validProposal(_proposalId)
        returns (
        string memory title,    
            string memory content,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 startTime,
            uint256 endTime,
            ProposalStatus status,
            address creator
        )
    {
        Proposal storage proposal = _proposals[_proposalId];
        return (
            proposal.title,
            proposal.content,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.status,
            proposal.creator
        );
    }

    function checkHasVoted(
        uint256 _proposalId,
        address _memberAddress
    ) public view validProposal(_proposalId) returns (bool) {
        require(
            msg.sender == _memberAddress,
            "Unauthorized: Can't access this data!"
        );
        return _hasVoted[_proposalId][_memberAddress];
    }

    function checkMemberInfo(
        address _memberAddress
    )
        public
        view
        returns (uint256 proposalsCreated, uint256 proposalsParticipatedIn)
    {
        require(
            msg.sender == _memberAddress,
            "Unauthorized: Can't access this data!"
        );
        Member storage member = _members[msg.sender];
        return (member.proposalsCreated, member.proposalsParticipatedIn);
    }
}
