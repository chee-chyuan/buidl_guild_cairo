%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, deploy
from structs.buidl_struct_v2 import BuidlInfo, PoolInfo, PoolReadInfo
from starkware.cairo.common.uint256 import Uint256
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc20.IERC20 import IERC20
from interfaces.IUserRegistrar import IUserRegistrar
from interfaces.IQfPool import IQfPool

# init stuff
@storage_var
func pool_contract_hash() -> (res: felt):
end

@storage_var
func salt() -> (value : felt):
end

@storage_var
func token_address() -> (res: felt):
end

@storage_var
func user_registrar() -> (res: felt):
end

# pool stuff
@storage_var
func pool_info(pool_id: felt) -> (res: PoolInfo):
end

@storage_var
func current_pool_length() -> (id: felt):
end

# buidl stuff
@storage_var
func total_buidl() -> (res: felt):
end

@storage_var
func buidls(buidl_id: felt) -> (res: BuidlInfo):
end

@storage_var
func buidl_ipfs(buidl_id: felt, index: felt) -> (str: felt):
end

@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(contract_hash: felt, user_registrar_: felt, erc20_addr_: felt, admin: felt):

    Ownable.initializer(admin)
    pool_contract_hash.write(contract_hash)
    user_registrar.write(user_registrar_)
    token_address.write(erc20_addr_)

    return ()
end

# init stuff
@view
func get_admin{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (admin: felt):
    let (res) = Ownable.owner()
    return (admin=res)
end

@view
func get_pool_contract_hash{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (res: felt):
    let (res) = pool_contract_hash.read()
    return (res=res)
end

@view
func get_salt{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (res: felt):
    let (res) = salt.read()
    return (res=res)
end

@view
func get_token_address{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (res: felt):
    let (res) = token_address.read()
    return (res=res)
end

@view
func get_user_registrar{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (res: felt):
    let (res) = user_registrar.read()
    return (res=res)
end

# pool stuff
@view
func get_current_pool_length{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (res: felt):
    let (res) = current_pool_length.read()
    return (res=res)
end

@view 
func get_pool_info_by_pool_id{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(pool_id: felt) -> (res: PoolInfo):
    let (res) = pool_info.read(pool_id)
    return (res=res)
end

# get all pools
@view 
func get_all_pools{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (res_len: felt, res: PoolReadInfo*):
    let (pool_len) = current_pool_length.read()
    let (info: PoolReadInfo*) = alloc()
    let (res_len, res) = get_all_pools_internal(0, pool_len, 0, info)

    return (res_len, res)
end


func get_all_pools_internal{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
    current_index: felt, 
    total_length: felt, 
    info_len: felt, 
    info: PoolReadInfo*
) -> (res_len: felt, res: PoolReadInfo*):

    if total_length == 0: 
        return (res_len=info_len, res=info)
    end

    let (current_info) = pool_info.read(current_index+1)
    let (total_contributed_fund) = IQfPool.get_total_project_contributed_fund(
                                            contract_address=current_info.address,
                                            ) 
    let (total_matched) = IQfPool.get_total_match(
                                            contract_address=current_info.address,
                                            ) 
    let (total_divisor) = IQfPool.get_total_divisor(
                                            contract_address=current_info.address,
                                            ) 

    let read_info = PoolReadInfo(
                        current_info.address,
                        current_info.vote_start_time,
                        current_info.vote_end_time,
                        current_info.stream_start_time,
                        current_info.stream_end_time,
                        total_matched,
                        total_divisor, 
                        total_contributed_fund
                    ) 
    assert info[current_index] = read_info

    let (res_len, res) = get_all_pools_internal(current_index+1, total_length-1, info_len+1, info)

    return (res_len, res)
end


# admin add pool
@external
func deploy_pool{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
    vote_start_time_ : felt,
    vote_end_time_: felt,
    stream_start_time_ : felt,
    stream_end_time_: felt,
):
    Ownable.assert_only_owner()
    let (token_addr) = token_address.read()
    let (core_contract_addr) = get_contract_address()

    let (calldata) = alloc()
    assert calldata[0] = token_addr
    assert calldata[1] = core_contract_addr
    assert calldata[2] = vote_start_time_
    assert calldata[3] = vote_end_time_
    assert calldata[4] = stream_start_time_
    assert calldata[5] = stream_end_time_

    let (current_salt) = salt.read()
    let (class_hash) = pool_contract_hash.read()
    let (contract_address) = deploy(
        class_hash=class_hash,
        contract_address_salt=current_salt,
        constructor_calldata_size=6,
        constructor_calldata=calldata,
        deploy_from_zero=0,
    )

    salt.write(value=current_salt + 1)

    let info = PoolInfo(contract_address, vote_start_time_, vote_end_time_, stream_start_time_, stream_end_time_)

    # add address
    let (pool_id) = current_pool_length.read()
    current_pool_length.write(pool_id+1)
    pool_info.write(pool_id+1, info)
    return ()
end

# user create buidl
@external 
func add_buidl{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
    ipfs_len: felt,
    ipfs: felt*,
):
    alloc_locals
    let (caller_addr) = get_caller_address()
    local caller_addr = caller_addr

    # check if caller_exist in user registrar
    assert_user_is_registered(caller_addr)

    let (current_len) = total_buidl.read()
    let buidl_id = current_len + 1
    total_buidl.write(buidl_id)

    let buidl_info = BuidlInfo(ipfs_len, 0, 0, 0, buidl_id, caller_addr)
    buidls.write(buidl_id, buidl_info)
    store_buidl_ipfs(buidl_id, 0, ipfs_len, ipfs)
    return ()
end

func store_buidl_ipfs{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
      buidl_id: felt,
      current_index: felt,
      ipfs_link_len: felt, 
      ipfs_link: felt*
    ):

    if ipfs_link_len == 0:
        return ()
    end

    buidl_ipfs.write(buidl_id=buidl_id, index=current_index, value=ipfs_link[0])
    store_buidl_ipfs(
                    buidl_id=buidl_id,
                    current_index=current_index+1, 
                    ipfs_link_len=ipfs_link_len-1, 
                    ipfs_link=&ipfs_link[1]
                )

    return ()
end

# get current buidl count
@view
func get_current_build_count{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (res: felt):
    let (res) = total_buidl.read()
    return (res=res)
end

@view
func get_builds_by_id{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
    buidl_id: felt
) -> (res: BuidlInfo):
    let (build) = buidls.read(buidl_id)
    return (build)
end

# get all buidl
@view
func get_all_builds{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
) -> (res_len: felt, res: BuidlInfo*): 
    let (len) = total_buidl.read()
    let (info: BuidlInfo*) = alloc()

    let (res_len, res) = get_all_builds_internal(0, len, 0, info)
    return (res_len, res)
end

func get_all_builds_internal{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
    current_index: felt, 
    total_length: felt, 
    info_len: felt, 
    info: BuidlInfo*
) -> (res_len: felt, res: BuidlInfo*): 

    if total_length == 0: 
        return (res_len=info_len, res=info)
    end

    let (build) = buidls.read(current_index+1)
    assert info[current_index] = build

    let (res_len, res) = get_all_builds_internal(current_index+1, total_length-1, info_len+1, info)

    return (res_len, res)
end

# get build ipfs by buidl id
@view
func get_build_ipfs{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(buidl_id: felt) -> (ipfs_len: felt, ipfs: felt*):
    let (info) = buidls.read(buidl_id)
    let length = info.ipfs_link_len
    let (link: felt*) = alloc()

    let (res_len, res) = get_build_ipfs_internal(buidl_id, 0, length, 0, link)
    return (res_len, res)
end

func get_build_ipfs_internal{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
        buidl_id: felt,
        current_index: felt,
        ipfs_len: felt, 
        link_len: felt, 
        link: felt*
    ) -> (ipfs_res_link_len: felt, ipfs_res_link: felt*):

    if ipfs_len == 0:
        return (ipfs_res_link_len=link_len, ipfs_res_link=link)
    end

    let (ipfs_index_link) = buidl_ipfs.read(buidl_id=buidl_id, index=current_index)
    assert [link + current_index] = ipfs_index_link

    let (len, ipfs_link) = get_build_ipfs_internal(
                                                    buidl_id=buidl_id,
                                                    current_index=current_index+1,
                                                    ipfs_len=ipfs_len-1,
                                                    link_len=link_len+1,
                                                    link=link
                                                )
                      
    return (ipfs_res_link_len=len, ipfs_res_link=ipfs_link)  
end

# user add buidl to pool (as a project)
@external 
func add_buidl_to_pool{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(buidl_id: felt, pool_id: felt):
    alloc_locals

    # check pool id exist
    let (_pool_info) = pool_info.read(pool_id=pool_id)
    local _pool_info: PoolInfo = _pool_info
    assert_not_zero(_pool_info.address)

    # check if buidl is correct
    assert_not_zero(buidl_id)
    let (_buidl_info) = buidls.read(buidl_id)
    let (caller) = get_caller_address()
    assert _buidl_info.user_addr = caller

    # check ipfs
    let (ipfs_len, ipfs) = get_build_ipfs(buidl_id)

    # create project in pool
    let (project_id) = IQfPool.add_project(
                            contract_address=_pool_info.address,
                            owner=caller,
                            ipfs_link_len=_buidl_info.ipfs_link_len,
                            ipfs_link=ipfs
                            )

    # override buidl in global
    let new_buidl_info = BuidlInfo(
                        ipfs_link_len=_buidl_info.ipfs_link_len, 
                        pool_id=pool_id,
                        pool_addr=_pool_info.address,
                        project_id=project_id,
                        buidl_id=buidl_id,
                        user_addr=caller
                        )

    buidls.write(buidl_id, new_buidl_info)
    return ()
end

# user submit proof of work (lol)
@external
func submit_work_proof{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(buidl_id: felt, ipfs_len: felt, ipfs: felt*):
    alloc_locals
    # check if user is registered to prevent QF from being gamed
    let (caller) = get_caller_address()
    assert_user_is_registered(caller)

    let (build) = buidls.read(buidl_id)
    assert build.user_addr = caller
    assert_not_zero(build.pool_id)

    IQfPool.submit_work_proof(contract_address=build.pool_addr, project_owner=caller, ipfs_len=ipfs_len, ipfs=ipfs)
    return ()
end

# admin approve progress
@external
func admin_verify_work{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(build_id: felt, approved_percentage: felt):
    alloc_locals
    Ownable.assert_only_owner()

    let (build) = buidls.read(build_id)
     # check pool id exist
    with_attr error_message("Build doesnt have a pool"):
        assert_not_zero(build.pool_addr)
    end

    IQfPool.admin_verify_work(contract_address=build.pool_addr, project_id=build.project_id, approved_percentage=approved_percentage)

    return ()
end

# vote

@external 
func vote{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(build_id: felt, amount: Uint256):
    alloc_locals
    # check if user is registered to prevent QF from being gamed
    let (caller) = get_caller_address()
    assert_user_is_registered(caller)

    let (build) = buidls.read(build_id)
     # check pool id exist
    with_attr error_message("Build doesnt have a pool"):
        assert_not_zero(build.pool_addr)
    end

    # # check pool id exist
    # let (pool_addr) = pool_address.read(pool_id=pool_id)
    # local pool_addr = pool_addr
    # with_attr error_message("Invalid Pool Id"):
    #     assert_not_zero(pool_addr)
    # end

    # transfer erc20 to pool
    let (erc20_addr) = token_address.read()
    let (transfer_res) = IERC20.transferFrom(contract_address=erc20_addr,
                        sender=caller,
                        recipient=build.pool_addr,
                        amount=amount)

    with_attr error_message("Transfer Erc20 fail"):
        assert transfer_res = 1
    end

    # vote
    IQfPool.vote(contract_address=build.pool_addr, project_id=build.project_id, amount=amount, voter_addr=caller)

    return ()
end

# claim
@external
func claim{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(buidl_id: felt):
    let (build) = buidls.read(buidl_id)
     # check pool id exist
    with_attr error_message("Build doesnt have a pool"):
        assert_not_zero(build.pool_addr)
    end

    IQfPool.claim(contract_address=build.pool_addr, project_owner=build.user_addr)
    return ()
end

func assert_user_is_registered{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(user: felt):
    let (user_registrar_addr) = user_registrar.read()

    let (is_registered) = IUserRegistrar.check_user_registered(contract_address=user_registrar_addr,
                                                               sender_address=user)
    with_attr error_message("User not registered"):
        assert is_registered = 1
    end

    return ()
end