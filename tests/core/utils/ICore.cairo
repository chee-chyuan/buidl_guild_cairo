%lang starknet

from src.structs.buidl_struct import BuidlInfo, BuidlProjectMapping

@contract_interface
namespace ICore:
    func get_admin() -> (admin: felt):
    end

    func get_pool_contract_hash() -> (res: felt):
    end

    func get_salt() -> (res: felt):
    end

    func get_token_address() -> (res: felt):
    end

    func get_user_registrar() -> (res: felt):
    end

    func get_current_pool_id() -> (res: felt):
    end

    func get_pool_address(pool_id: felt) -> (res: felt):
    end

    func get_user_current_buidl_id(user_addr: felt) -> (id: felt):
    end

    func get_user_buidl(user_addr: felt, buidl_id: felt) -> (res: BuidlInfo):
    end

    func get_user_buidl_ipfs(
        user_addr: felt, 
        buidl_id: felt,
        current_index: felt,
        ipfs_len: felt, 
        link_len: felt, 
        link: felt*
    ) -> (ipfs_res_link_len: felt, ipfs_res_link: felt*):
    end

    func get_user_buidl_project_len(user_addr: felt) -> (len: felt):
    end

    func get_user_buidl_project_mapping(user_addr: felt, index: felt) -> (res: BuidlProjectMapping):
    end

    func deploy_pool(
        vote_start_time_ : felt,
        vote_end_time_: felt,
        stream_start_time_ : felt,
        stream_end_time_: felt,
    ):
    end

    func add_buidl(
        ipfs_len: felt,
        ipfs: felt*,
    ):
    end

    func add_buidl_to_pool(buidl_id: felt, pool_id: felt):
    end
end