%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, deploy
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc20.IERC20 import IERC20
from structs.buidl_struct import BuidlInfo, BuidlProjectMapping
from interfaces.IUserRegistrar import IUserRegistrar
from interfaces.IQfPool import IQfPool

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

@storage_var
func pool_address(pool_id: felt) -> (address: felt):
end

@storage_var
func current_pool_id() -> (id: felt):
end

@storage_var
func user_current_buidl_id(user_addr: felt) -> (id: felt):
end

@storage_var
func user_buidl(user_addr: felt, buidl_id: felt) -> (res: BuidlInfo):
end

@storage_var
func user_buidl_ipfs(user_addr: felt, buidl_id: felt, index: felt) -> (str: felt):
end

@storage_var
func user_buidl_project_len(user_addr: felt) -> (len: felt):
end

@storage_var
func user_buidl_project_mapping(user_addr: felt, index: felt) -> (res: BuidlProjectMapping):
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
    current_pool_id.write(1)
    token_address.write(erc20_addr_)

    return ()
end

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

@view
func get_current_pool_id{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (res: felt):
    let (res) = current_pool_id.read()
    return (res=res)
end

@view 
func get_pool_address{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(pool_id: felt) -> (res: felt):
    let (res) = pool_address.read(pool_id)
    return (res=res)
end

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

    # add address
    let (pool_id) = current_pool_id.read()
    current_pool_id.write(pool_id+1)
    pool_address.write(pool_id, contract_address)
    return ()
end

@view
func get_user_current_buidl_id{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(user_addr: felt) -> (id: felt):
    let (res) = user_current_buidl_id.read(user_addr)

    return (id=res)
end

@view
func get_user_buidl{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(user_addr: felt, buidl_id: felt) -> (res: BuidlInfo):
    let (res) = user_buidl.read(user_addr, buidl_id)
    return (res=res)
end

@view
func get_user_buidl_ipfs{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        user_addr: felt, 
        buidl_id: felt,
        current_index: felt,
        ipfs_len: felt, 
        link_len: felt, 
        link: felt*
    ) -> (ipfs_res_link_len: felt, ipfs_res_link: felt*):
    if ipfs_len == 0:
        return (ipfs_res_link_len=link_len, ipfs_res_link=link)
    end

    let (ipfs_index_link) = user_buidl_ipfs.read(user_addr=user_addr, buidl_id=buidl_id, index=current_index)
    assert [link + current_index] = ipfs_index_link

    let (len, ipfs_link) = get_user_buidl_ipfs(
                                                    user_addr=user_addr, 
                                                    buidl_id=buidl_id,
                                                    current_index=current_index+1,
                                                    ipfs_len=ipfs_len-1,
                                                    link_len=link_len+1,
                                                    link=link
                                                )
                      
    return (ipfs_res_link_len=len, ipfs_res_link=ipfs_link)     
end

@view
func get_user_buidl_project_len{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(user_addr: felt) -> (len: felt):
    let (res) = user_buidl_project_len.read(user_addr)
    return (len=res)
end

@view
func get_user_buidl_project_mapping{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(user_addr: felt, index: felt) -> (res: BuidlProjectMapping):

    let (res) = user_buidl_project_mapping.read(user_addr, index)
    return(res=res)
end

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
    # buidl_id starts from 0 so we need to increment first
    let (caller_addr) = get_caller_address()
    local caller_addr = caller_addr

    # check if caller_exist in user registrar
    assert_user_is_registered(caller_addr)

    let (current_buidl_id) = user_current_buidl_id.read(caller_addr)
    let buidl_id = current_buidl_id + 1
    user_current_buidl_id.write(caller_addr, buidl_id)

    let buidl_info = BuidlInfo(ipfs_len)
    user_buidl.write(caller_addr, buidl_id, buidl_info)
    store_ipfs(caller_addr, buidl_id, 0, ipfs_len, ipfs)
    return ()
end

func store_ipfs{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
      user_addr: felt,
      buidl_id: felt,
      current_index: felt,
      ipfs_link_len: felt, 
      ipfs_link: felt*
    ):

    if ipfs_link_len == 0:
        return ()
    end

    user_buidl_ipfs.write(user_addr=user_addr, buidl_id=buidl_id, index=current_index, value=ipfs_link[0])
    store_ipfs(
                    user_addr=user_addr, 
                    buidl_id=buidl_id,
                    current_index=current_index+1, 
                    ipfs_link_len=ipfs_link_len-1, 
                    ipfs_link=&ipfs_link[1]
                )

    return ()
end

@external
func admin_init_matched_fund_in_pool{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(pool_id: felt, amount: Uint256):
    alloc_locals
    Ownable.assert_only_owner()

    # check pool id exist
    let (pool_addr) = pool_address.read(pool_id=pool_id)
    local pool_addr = pool_addr
    assert_not_zero(pool_addr)

    # transfer erc20 to pool
    let (erc20_addr) = token_address.read()
    let (caller) = get_caller_address()
    let (transfer_res) = IERC20.transferFrom(contract_address=erc20_addr,
                        sender=caller,
                        recipient=pool_addr,
                        amount=amount)

    with_attr error_message("Transfer Erc20 fail"):
        assert transfer_res = 1
    end

    IQfPool.init_matched_pool(contract_address=pool_addr)

    return ()
end

@external 
func add_buidl_to_pool{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(buidl_id: felt, pool_id: felt):
    alloc_locals
    let (caller) = get_caller_address()

    # check if buidl_id < user_current_buidl_id
    assert_not_zero(buidl_id)
    let (current_buidl_id) = user_current_buidl_id.read(caller)
    assert_le(buidl_id, current_buidl_id)

    # check pool id exist
    let (pool_addr) = pool_address.read(pool_id=pool_id)
    local pool_addr = pool_addr
    assert_not_zero(pool_addr)

    let (buidl_info) = user_buidl.read(user_addr=caller, buidl_id=buidl_id)

    let (ipfs) = alloc()

    let (ipfs_len, ipfs_res) = get_user_buidl_ipfs(
                                        caller, 
                                        buidl_id, 
                                        0, 
                                        buidl_info.ipfs_link_len, 
                                        0, 
                                        ipfs)


    let (project_id) = IQfPool.add_project(
                            contract_address=pool_addr,
                            owner=caller,
                            ipfs_link_len=buidl_info.ipfs_link_len,
                            ipfs_link=ipfs_res
                            )

    # store in build_project_mapping
    let mapping = BuidlProjectMapping(pool_id, pool_addr, project_id)

    let (current_len) = user_buidl_project_len.read(caller)
    user_buidl_project_len.write(caller, current_len+1)

    user_buidl_project_mapping.write(caller, current_len, mapping)
    return ()
end

@external 
func vote{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(pool_id: felt, project_id: felt, amount: Uint256):
    alloc_locals
    # check if user is registered to prevent QF from being gamed
    let (caller) = get_caller_address()
    assert_user_is_registered(caller)

    # check pool id exist
    let (pool_addr) = pool_address.read(pool_id=pool_id)
    local pool_addr = pool_addr
    with_attr error_message("Invalid Pool Id"):
        assert_not_zero(pool_addr)
    end

    # transfer erc20 to pool
    let (erc20_addr) = token_address.read()
    let (transfer_res) = IERC20.transferFrom(contract_address=erc20_addr,
                        sender=caller,
                        recipient=pool_addr,
                        amount=amount)

    with_attr error_message("Transfer Erc20 fail"):
        assert transfer_res = 1
    end

    # vote
    IQfPool.vote(contract_address=pool_addr, project_id=project_id, amount=amount, voter_addr=caller)

    return ()
end

@external
func submit_work_proof{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(pool_id: felt, ipfs_len: felt, ipfs: felt*):
    alloc_locals
    # check if user is registered to prevent QF from being gamed
    let (caller) = get_caller_address()
    assert_user_is_registered(caller)

     # check pool id exist
    let (pool_addr) = pool_address.read(pool_id=pool_id)
    local pool_addr = pool_addr
    with_attr error_message("Invalid Pool Id"):
        assert_not_zero(pool_addr)
    end

    IQfPool.submit_work_proof(contract_address=pool_addr, project_owner=caller, ipfs_len=ipfs_len, ipfs=ipfs)
    return ()
end

@external
func admin_verify_work{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(pool_id: felt, project_id: felt, approved_percentage: felt):
    alloc_locals
    Ownable.assert_only_owner()
     # check pool id exist
    let (pool_addr) = pool_address.read(pool_id=pool_id)
    local pool_addr = pool_addr
    with_attr error_message("Invalid Pool Id"):
        assert_not_zero(pool_addr)
    end

    IQfPool.admin_verify_work(contract_address=pool_addr, project_id=project_id, approved_percentage=approved_percentage)

    return ()
end

@external
func claim{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(pool_id: felt, owner: felt):
    # check pool id exist
    alloc_locals
    let (pool_addr) = pool_address.read(pool_id=pool_id)
    local pool_addr = pool_addr
    assert_not_zero(pool_addr)

    IQfPool.claim(contract_address=pool_addr, project_owner=owner)
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