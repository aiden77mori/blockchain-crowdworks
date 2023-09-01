//SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DappWork is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private totalJobListings;
    Counters.Counter private totalFreelancers;

    uint totalBalance;

    struct JobStruct {
        uint id;
        address owner;
        string jobTitle;
        string description;
        string tags;
        uint price;
        bool completed;
        bool paidOut;
        bool listed;
        bool timestamp;
    }

    struct FreelancerStruct {
        uint id;
        uint jId;
        address freelancer;
        bool accepted;
    }

    struct BidStruct {
        uint jId;
        address bidder;
    }

    mapping(uint => JobStruct) jobListings;
    mapping(uint => mapping(uint => FreelancerStruct)) freelancers;
    mapping(uint => BidStruct[]) jobBidders;

    mapping(uint => bool) jobListingExists;
    mapping(uint => bool) freelancerExists;

    function addJobListing(
        string memory jobTitle,
        string memory description,
        string memory tags,
        uint price,
    ) public payable {
        require(bytes(jobTitle).length > 0, "Please provide a job title");
        require(bytes(description).length > 0, "Please provide a description");
        require(bytes(tags).length > 0, "Please provide tags");
        require(numOfFreelancers > 0, "Minimum of one freelancers required");
        require(price > 0 ether, "Please indicate the price");
        require(duration > 0, "Provide a valid timestamp");

        totalBalance += price;
        totalJobListings.increment();

        uint id = totalJobListings.current();

        jobListings[id].id = id;
        jobListings[id].owner = msg.sender;
        jobListings[id].jobTitle = jobTitle;
        jobListings[id].description = description;
        jobListings[id].tags = tags;
        jobListings[id].price = price;
        jobListings[id].listed = true;
        jobListings[id].timestamp = currentTime();

        jobListingExists[id] = true;
    }

    function unListJob(uint id) public {
        require(jobListingExists[id], "This job listing doesn't exist");
        require(!jobListings[id].completed, "This job has been completed");
        require(!jobListings[id].paidOut, "This job has been paid out");

        jobListings[id].listed = false;
        jobListingExists[id] = false;
    }

    function bidForJob(uint id) public {
        require(jobListingExists[id], "This job listing doesn't exist");
        require(!jobListings[id].completed, "This job has been completed");
        require(!jobListings[id].paidOut, "This job has been paid out");

        BidStruct memory bid;
        bid.jId  = id;
        bid.bidder = msg.sender;

        jobBidders[id].push(bid);
    }

    function acceptBid(uint jId, address bidder) public {
        require(jobListingExists[jId], "This job listing doesn't exist");
        require(!jobListings[jId].completed, "This job has been completed");
        require(!jobListings[jId].listed, "This job may have been taken or doesn't exist");
        require(!jobListings[jId].paidOut, "This job has been paid out");

        totalFreelancers.increment();
        uint id = totalFreelancers.current();
        freelancers[jId][id].id = id;
        freelancers[jId][id].jId = jId;
        freelancers[jId][id].freelancer = bidder;
        freelancers[jId][id].accepted = true;

        jobListings[jId].listed = false;
    }



    function getJobs() public view returns (JobStruct[] memory ActiveJobs) {
        uint available;

        for (uint256 i = 1; i <= totalJobListings.current(); i++) {
            if (!jobListings[i].listed && !jobListings[i].paidOut && !jobListings[i].completed) {
                available++;
            }
        }

        ActiveJobs = new JobStruct[](available);
        uint index;

        for (uint256 i = 1; i <= totalJobListings.current(); i++) {
            if (!jobListings[i].listed && !jobListings[i].paidOut && !jobListings[i].completed) {
                ActiveJobs[index++] = jobListings[i];
            }
        }
    }

    function getJob(uint id) public view returns (JobStruct memory) {
        return jobListings[id];
    }

    // private function

    function currentTime() internal view returns (uint256) {
        return (block.timestamp * 1000) + 1000;
    }

    function payTo(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success);
    }

}