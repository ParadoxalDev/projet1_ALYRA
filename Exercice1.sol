// SPDX-License-Identifier: MIT

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    Voter[] public voters;
    Proposal[] public proposals;

    mapping(address => Voter) registered;
    mapping(uint256 => address) propositions;

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public status;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    function registration(address _elector) public onlyOwner {
        require(
            !registered[_elector].isRegistered,
            unicode"Vous êtes déja enregistré!"
        );
        require(
            status == WorkflowStatus.RegisteringVoters,
            unicode"les enregistrements sont terminés"
        );
        registered[_elector].isRegistered = true;
        voters.push(Voter(true, false, 0));
        emit VoterRegistered(_elector);
    }

    function openingProposal() public onlyOwner {
        require(
            status == WorkflowStatus.RegisteringVoters,
            unicode"les enregistrements sont terminés"
        );
        status = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            WorkflowStatus.ProposalsRegistrationStarted
        );
    }

    function giveYourProposal(string memory _proposition) public {
        require(
            registered[msg.sender].isRegistered,
            unicode"vous n'êtes pas sur la liste"
        );
        require(
            status == WorkflowStatus.ProposalsRegistrationStarted,
            unicode"L'ouverture des propositions n'a pas encore eu lieux"
        );
        proposals.push(Proposal(_proposition, 0));
        propositions[proposals.length - 1] = msg.sender;
        emit ProposalRegistered(proposals.length - 1);
    }

    function getTotalProposal() public view returns (uint256) {
        return proposals.length;
    }

    function closingProposal() public onlyOwner {
        status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            WorkflowStatus.ProposalsRegistrationEnded
        );
    }

    function openingVote() public onlyOwner {
        require(
            status == WorkflowStatus.ProposalsRegistrationEnded,
            unicode"La fermeture des propositions n'a pas encore eu lieux"
        );
        status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VotingSessionStarted
        );
    }

    function voteNow(uint256 _idPropositionSoutenue) public {
        require(
            registered[msg.sender].isRegistered,
            unicode"vous n'êtes pas sur la liste"
        );
        require(
            !registered[msg.sender].hasVoted,
            unicode"Vous avez déja voté!"
        );
        require(
            status == WorkflowStatus.VotingSessionStarted,
            unicode"L'ouverture des votes n'a pas encore eu lieux"
        );
        proposals[_idPropositionSoutenue].voteCount += 1;
        registered[msg.sender].hasVoted = true;
        registered[msg.sender].votedProposalId = _idPropositionSoutenue;
        emit Voted(msg.sender, _idPropositionSoutenue);
    }

    function closingVote() public onlyOwner {
        require(
            status == WorkflowStatus.VotingSessionStarted,
            unicode"L'ouverture des votes n'a pas encore eu lieux"
        );
        status = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
    }

    function heVotedFor(address _elector) public view returns (uint256) {
        require(
            registered[_elector].hasVoted,
            unicode"Cette personne n'a pas émis de vote"
        );
        return registered[_elector].votedProposalId;
    }

    function getWinner()
        public
        returns (
            Proposal memory winningProposal,
            uint256 _idProposal,
            address _winner
        )
    {
        require(
            status == WorkflowStatus.VotingSessionEnded,
            unicode"La fermeture des votes n'a pas encore eu lieux"
        );
        status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
        Proposal memory propos = proposals[0];
        uint256 index;
        for (uint256 i = 1; i < proposals.length; i++) {
            if (proposals[i].voteCount > propos.voteCount) {
                propos = proposals[i];
                index = i;
            }
        }
        winningProposal = propos;
        _idProposal = index;
        _winner = propositions[index];
    }

    function resetAll() public onlyOwner {
        require(
            status == WorkflowStatus.VotesTallied,
            unicode"La proposition gagnante n'a pas été dévoilée"
        );

        //   for(uint i = proposals.length; i > 0; i--){
        //
        //  }
        delete status;
    }
}
