%lang starknet

struct github_username:
    member prefix : felt
    member suffix : felt
end

@contract_interface
namespace IUserRegistrar:

    func check_user_registered(sender_address : felt) -> (is_registered : felt):
    end

    func get_user_info() -> (
        github : github_username, ipfs_url_len : felt, ipfs_url : felt*):
    end

    func register(github_prefix : felt, github_suffix : felt, ipfs_url_len : felt, ipfs_url : felt*):
    end
end