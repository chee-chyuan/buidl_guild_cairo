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