%lang starknet
from starkware.cairo.common.uint256 import Uint256

struct ProjectInfo:
    member ipfs_link_len: felt
    member owner: felt
end

struct ProjectVote:
    member c: Uint256
    member c_sqrt: Uint256
end

struct ProjectAccumulator:
    member sum_c: Uint256
    member sum_c_sqrt: Uint256
    member square_sum_c_sqrt: Uint256
end

# for users to submit proof of completion
# and for admin to approve claimmable percentage
struct ProjectVerification:
    member submission_ipfs_link_len: felt
    member admin_latest_approved_percentage: felt
    member is_approved_latest_submission: felt
end

# used to get all related info when returning
struct ProjectReturn:
    member ipfs_link_len: felt
    member owner: felt
    member sum_c: Uint256
    member sum_c_sqrt: Uint256
    member square_sum_c_sqrt: Uint256
    member submission_ipfs_link_len: felt
    member admin_latest_approved_percentage: felt
    member is_approved_latest_submission: felt
end