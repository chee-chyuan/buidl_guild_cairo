%lang starknet
from starkware.cairo.common.uint256 import Uint256
from src.structs.project_struct import ProjectInfo, ProjectAccumulator, ProjectVote

@contract_interface
namespace IQfPool:

    func get_current_project_id() -> (res: felt):
    end

    func get_erc20_addr() -> (res: felt):
    end

    func get_owner() -> (res: felt):
    end

    func get_project_vote(project_id: felt, voter_addr: felt) -> (res: ProjectVote):
    end

    func get_project_accumulator(project_id: felt) -> (res: ProjectAccumulator):
    end

    func get_total_project_contributed_fund() -> (res: Uint256):
    end

    func get_total_match() -> (res: Uint256):
    end

    func get_vote_start_time() -> (res: felt):
    end

    func get_vote_end_time() -> (res: felt):
    end

    func get_stream_start_time() -> (res: felt):
    end

    func get_stream_end_time() -> (res: felt):
    end

    func init_matched_pool():
    end

    func add_project(
        owner: felt, 
        ipfs_link_len: felt, 
        ipfs_link: felt*
    ):
    end

    func get_project_info(project_id: felt) -> (res: ProjectInfo):
    end

    func get_project_ipfs_link(
        project_id: felt, 
        current_index: felt,
        ipfs_len: felt, 
        link_len: felt, 
        link: felt*
    ) -> (ipfs_res_link_len: felt, ipfs_res_link: felt*):
    end
end
