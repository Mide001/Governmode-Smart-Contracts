const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GovernMode Contract", function () {
  let governModeContract;
  let admin;
  let member1;
  let member2;

  beforeEach(async function () {
    [admin, member1, member2] = await ethers.getSigners();
    const GovernMode = await ethers.getContractFactory("GovernMode");
    governModeContract = await GovernMode.deploy();
    await governModeContract.deployed();
  });

  it("Should create a proposal", async function () {
    const proposalTitle = "Test Proposal";
    const proposalContent = "This is a test proposal.";
    const durationInDays = 7;

    await governModeContract.connect(member1).createProposal(proposalTitle, proposalContent, durationInDays);

    const proposalDetails = await governModeContract.getProposalDetails(1);

    expect(proposalDetails.title).to.equal(proposalTitle);
    expect(proposalDetails.content).to.equal(proposalContent);
    expect(proposalDetails.startTime).to.be.above(0);
    expect(proposalDetails.endTime).to.be.above(0);
    expect(proposalDetails.creator).to.equal(member1.address);
  });

  it("Should allow a member to vote on a proposal", async function () {
    const proposalTitle = "Test Proposal";
    const proposalContent = "This is a test proposal.";
    const durationInDays = 7;

    await governModeContract.connect(member1).createProposal(proposalTitle, proposalContent, durationInDays);

    await governModeContract.connect(member2).vote(1, true);

    const hasVoted = await governModeContract.connect(member2).checkHasVoted(1, member2.address);
    const proposalDetails = await governModeContract.getProposalDetails(1);

    expect(hasVoted).to.be.true;
    expect(proposalDetails.forVotes).to.equal(1);
  });
})