%lang starknet
from starkware.cairo.common.uint256 import Uint256

struct BuidlInfo:
    member ipfs_link_len: felt
    member pool_id: felt
    member pool_addr: felt
    member project_id: felt # the project id in the pool
    member buidl_id: felt # the buidl_id of a user
    member user_addr: felt
end

struct PoolInfo: 
    member address: felt
    member vote_start_time : felt
    member vote_end_time: felt
    member stream_start_time : felt
    member stream_end_time: felt
end

struct PoolReadInfo:
    member address: felt
    member vote_start_time : felt
    member vote_end_time: felt
    member stream_start_time : felt
    member stream_end_time: felt
    member total_matched: Uint256 
    member total_divisor: Uint256
    member total_project_contributed_fund: Uint256
end