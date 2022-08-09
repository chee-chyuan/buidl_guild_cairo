struct BuidlInfo:
    member ipfs_link_len: felt
end

struct BuidlProjectMapping: 
    member pool_id: felt
    member pool_addr: felt
    member project_id: felt # the project id in the pool
    member buidl_id: felt # the buidl_id of a user
    member user_addr: felt
end