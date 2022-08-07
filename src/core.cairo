%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, deploy
from openzeppelin.access.ownable.library import Ownable
from structs.buidl_struct import BuidlInfo
from interfaces.IUserRegistrar import IUserRegistrar

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

@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(contract_hash: felt, user_registrar_: felt):

    let (admin) = get_caller_address()
    Ownable.initializer(admin)
    pool_contract_hash.write(contract_hash)
    user_registrar.write(user_registrar_)
    current_pool_id.write(1)

    return ()
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