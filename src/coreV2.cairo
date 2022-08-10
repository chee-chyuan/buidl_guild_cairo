%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, deploy
from structs.buidl_struct_v2 import BuidlInfo, PoolInfo, PoolReadInfo
from openzeppelin.access.ownable.library import Ownable
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
func buidls(index: felt) -> (res: BuidlInfo):
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

# user add buidl to pool (as a project)

# user submit proof of work (lol)

# admin approve progress

# vote

# claim

# get all pool with all info

# get current buidl count

# get all buidl

# get build ipfs by id