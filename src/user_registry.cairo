%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address

struct github_username:
    member prefix : felt
    member suffix : felt
end

@storage_var
func current_user_id() -> (next : felt):
end
@storage_var
func user_ipfs_len(user_addr : felt) -> (ipfs_url_len : felt):
end
@storage_var
func ipfs_by_address_by_index(user_addr : felt, index : felt) -> (url : felt):
end
@storage_var
func user_to_github(user_addr : felt) -> (github : github_username):
end
@storage_var
func github_to_user(github_prefix : felt, github_suffix : felt) -> (user_addr : felt):
end
@storage_var
func user_registered(user_addr : felt) -> (is_registered : felt):
end


@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    ## We might to set up a vault address somwhere here or in another setter function
    return ()
end

@view
func check_user_registered{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(sender_address : felt) -> (is_registered : felt):
    let (is_registered) = user_registered.read(sender_address)
    return (is_registered=is_registered)
end

@view
func get_user_info{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        github : github_username, ipfs_url_len : felt, ipfs_url : felt*):

    alloc_locals
    let (sender_address) = get_caller_address()
    let (ipfs_url_len) = user_ipfs_len.read(sender_address)
    let (ipfs_url) = alloc()
    read_ipfs(sender_address,ipfs_url_len,ipfs_url)
    let (github) = user_to_github.read(sender_address)
    return (github,ipfs_url_len,ipfs_url)

end

@external
func register{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(github_prefix : felt, github_suffix : felt, ipfs_url_len : felt, ipfs_url : felt*):

    alloc_locals
    let (sender_address) = get_caller_address()
    assert_user_not_registered(sender_address)
    assert_github_link_available(github_prefix, github_suffix)
    let github_username_instance = github_username(
        prefix=github_prefix,
        suffix=github_suffix
    )
    user_to_github.write(sender_address,github_username_instance)
    github_to_user.write(github_prefix,github_suffix,sender_address)
    user_ipfs_len.write(sender_address,ipfs_url_len)
    write_ipfs(sender_address,ipfs_url_len, ipfs_url)
    user_registered.write(sender_address,1)
    return ()
end

## internals

func write_ipfs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(user_addr : felt, ipfs_url_len : felt, ipfs_url : felt*):
    if ipfs_url_len == 0:
        return ()
    end
    ipfs_by_address_by_index.write(user_addr,ipfs_url_len,ipfs_url[0])
    write_ipfs(user_addr,ipfs_url_len-1,&ipfs_url[1])
    return()
end

func read_ipfs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(user_addr : felt, ipfs_url_len : felt, ipfs_url : felt*):
    if ipfs_url_len == 0:
        return ()
    end
    let (url) = ipfs_by_address_by_index.read(user_addr,ipfs_url_len)
    assert ipfs_url[0] = url
    read_ipfs(user_addr,ipfs_url_len-1,ipfs_url+1)
    return ()
end

## Modifiers

func assert_user_not_registered{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(user_address: felt):

     with_attr error_message("User is registered"):
            let (is_registered) = user_registered.read(user_address)
            assert is_registered = 0
     end
    
    return ()
end

func assert_github_link_available{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(github_preffix : felt, github_suffix : felt):

     with_attr error_message("Github already taken"):
            let (user_addr) = github_to_user.read(github_preffix,github_suffix)
            assert user_addr = 0
     end
    
    return ()
end


