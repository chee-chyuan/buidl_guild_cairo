%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt, assert_le, assert_not_zero
from starkware.starknet.common.syscalls import get_contract_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_sub, uint256_mul, uint256_sqrt, uint256_add
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc20.IERC20 import IERC20
from structs.project_struct import ProjectInfo, ProjectVote, ProjectAccumulator

@storage_var
func erc20_addr() -> (addr: felt):
end

@storage_var
func initalized_matched_value() -> (is_init: felt):
end

# this is the current project id that will be used, after that it will get incremented
@storage_var
func current_project_id() -> (next: felt):
end

@storage_var
func project_info(project_id: felt) -> (info: ProjectInfo):
end

@storage_var
func reverse_user_project_id(owner: felt) -> (project_id: felt):
end

@storage_var
func project_ipfs_link(project_id: felt, index: felt) -> (link_partial: felt):
end

@storage_var
func vote_start_time() -> (time: felt):
end

@storage_var
func vote_end_time() -> (time: felt):
end

@storage_var
func stream_start_time() -> (time: felt):
end

@storage_var
func stream_end_time() -> (time: felt):
end

@storage_var
func claimed(project_id: felt) -> (claimed_amount: Uint256):
end

@storage_var
func project_vote(project_id: felt, voter_addr: felt) -> (vote: ProjectVote):
end

@storage_var
func project_accumulator(project_id: felt) -> (accumulator: ProjectAccumulator):
end

@storage_var
func total_project_contributed_fund()->(total_contributed: Uint256):
end

@storage_var
func total_match() -> (fund: Uint256):
end

@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
    _erc20_addr: felt,
    core_contract_addr: felt,
    _vote_start_time: felt,
    _vote_end_time: felt,
    _stream_start_time: felt,
    _stream_end_time: felt
):
    erc20_addr.write(_erc20_addr)
    Ownable.initializer(core_contract_addr)
    vote_start_time.write(_vote_start_time)
    vote_end_time.write(_vote_end_time)
    stream_start_time.write(_stream_start_time)
    stream_end_time.write(_stream_end_time)
    current_project_id.write(1) # start from id = 1

    return ()
end

@view
func get_current_project_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (id:felt):
    let (res) = current_project_id.read()
    return (id=res)
end

@view
func get_erc20_addr{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (addr:felt):
    let (res) = erc20_addr.read()
    return (addr=res)
end

@view
func get_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (owner:felt):
    let (res) = Ownable.owner()
    return (owner=res)
end

@view
func get_project_vote{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt, voter_addr: felt) -> (res: ProjectVote):
    let (res) = project_vote.read(project_id=project_id, voter_addr=voter_addr)
    return (res=res)
end

@view
func get_project_accumulator{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt) -> (res: ProjectAccumulator):
    let (res) = project_accumulator.read(project_id=project_id)
    return (res=res)
end

@view
func get_total_project_contributed_fund{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (total: Uint256):

    let (res) = total_project_contributed_fund.read()
    return (total=res)
end

@view
func get_total_match{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (matched: Uint256):

        let (res) = total_match.read()
        return (matched=res)
    end

@view
func get_vote_start_time{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> (time: felt):
    let (res) = vote_start_time.read()
    return (time=res)
end

@view
func get_vote_end_time{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}() -> (time: felt):
    let (res) = vote_end_time.read()
    return (time=res)
end

@view
func get_stream_start_time{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}() -> (time: felt):
    let (res) = stream_start_time.read()
    return (time=res)
end

@view
func get_stream_end_time{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}() -> (time: felt):
    let (res) = stream_end_time.read()
    return (time=res)
end

@view
func get_claimed_amount_by_project{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(project_id: felt) -> (amount: Uint256):
    let (res) = claimed.read(project_id=project_id)
    return (amount=res)
end

# flow:
# deploy this contract, transfer erc20 to this contract, set matched value

@external
func init_matched_pool{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}():

    with_attr error_message("Has been initialized"):
        let (is_init) = initalized_matched_value.read()
        assert is_init = 0
    end

    let (erc20) = erc20_addr.read()
    let (contract_address) = get_contract_address()
    let (balance) = IERC20.balanceOf(contract_address=erc20, account=contract_address)

    total_match.write(balance)
    initalized_matched_value.write(1)

    return ()
end

@external
func add_project{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
      owner: felt, 
      ipfs_link_len: felt, 
      ipfs_link: felt*
    ):

    # allows project to be added at any time
    # we wont be checking for duplicates ipfs_link

    # check if owner has created a pool before
    with_attr error_message("Owner already has a project in the current pool"):
            let (pool_id) = reverse_user_project_id.read(owner)
            assert pool_id = 0
     end

    let info = ProjectInfo(ipfs_link_len=ipfs_link_len, owner=owner)
    let (current_id) = current_project_id.read()
    current_project_id.write(current_id + 1)

    project_info.write(project_id=current_id, value=info)
    reverse_user_project_id.write(owner, current_id)
    store_ipfs_link(project_id=current_id, current_index=0, ipfs_link_len=ipfs_link_len, ipfs_link=ipfs_link)
    return()
end

func store_ipfs_link{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
      project_id: felt,
      current_index: felt,
      ipfs_link_len: felt, 
      ipfs_link: felt*
    ):

    if ipfs_link_len == 0:
        return ()
    end

    project_ipfs_link.write(project_id=project_id, index=current_index, value=ipfs_link[0])
    store_ipfs_link(
                    project_id=project_id, 
                    current_index=current_index+1, 
                    ipfs_link_len=ipfs_link_len-1, 
                    ipfs_link=&ipfs_link[1]
                )

    return ()
end

@view
func get_project_info{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt) -> (res: ProjectInfo):
    let (res) = project_info.read(project_id)
    return (res=res)
end

@view 
func get_reverse_user_project_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(owner:felt) -> (project_id: felt):
    let (res) = reverse_user_project_id.read(owner)

    return (project_id=res)
end

@view
func get_project_ipfs_link{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        project_id: felt, 
        current_index: felt,
        ipfs_len: felt, 
        link_len: felt, 
        link: felt*
    ) -> (ipfs_res_link_len: felt, ipfs_res_link: felt*):

    if ipfs_len == 0:
        return (ipfs_res_link_len=link_len, ipfs_res_link=link)
    end

    let (ipfs_index_link) = project_ipfs_link.read(project_id=project_id, index=current_index)
    assert [link + current_index] = ipfs_index_link

    let (len, ipfs_link) = get_project_ipfs_link(
                                                    project_id=project_id, 
                                                    current_index=current_index+1,
                                                    ipfs_len=ipfs_len-1,
                                                    link_len=link_len+1,
                                                    link=link
                                                )
                      
    return (ipfs_res_link_len=len, ipfs_res_link=ipfs_link)                          
end

@external
func vote2{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt, amount: Uint256, voter_addr: felt):

    alloc_locals

    local syscall_ptr_temp: felt*
    syscall_ptr_temp = syscall_ptr

    local pedersen_ptr_temp: HashBuiltin*
    pedersen_ptr_temp = pedersen_ptr

    local range_check_ptr_temp
    range_check_ptr_temp = range_check_ptr

    local c_old: Uint256

    Ownable.assert_only_owner()
    assert_only_within_voting_period()
    assert_project_exist(project_id)
    return ()
end

# this function can only be called by the 'owner' (i.e the contract that deploys this contract)
@external
func vote{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt, amount: Uint256, voter_addr: felt):
    alloc_locals

    local syscall_ptr_temp: felt*
    syscall_ptr_temp = syscall_ptr

    local pedersen_ptr_temp: HashBuiltin*
    pedersen_ptr_temp = pedersen_ptr

    local range_check_ptr_temp
    range_check_ptr_temp = range_check_ptr

    local c_old: Uint256

    Ownable.assert_only_owner()
    assert_only_within_voting_period()
    assert_project_exist(project_id)
    
    # transfer fund to this contract by owner before calling this function
    # thus, amount passed in can be trusted

    # get current ProjectVote
    let (current_project_vote) = project_vote.read(project_id=project_id, voter_addr=voter_addr)

    # check if vote exist by checking ProjectInfo
    # if so 
    # save c value as c_old
    # minus c from sum_c
    # minus c from total_project_contributed_fund (i dont think we need as we will add in c_old also later)(ignore for now)
    # minus c_sqrt from sum_c_sqrt
    # recalculate square_sum_c_sqrt by squaring sum_c_sqrt
    # update project acummulator
    let (is_c_zero) = uint256_eq(current_project_vote.c, Uint256(0,0))

    if is_c_zero == 1:
        c_old.low = current_project_vote.c.low
        c_old.high = current_project_vote.c.high

        let (current_project_accumulator) = project_accumulator.read(project_id=project_id)
        let (sum_c_updated) = uint256_sub(current_project_accumulator.sum_c, c_old)

        # let (c_sqrt_to_minus) = uint256_sqrt(c_old)
        let c_sqrt_to_minus = current_project_vote.c_sqrt
        let (sum_c_sqrt_updated) = uint256_sub(current_project_accumulator.sum_c_sqrt, c_sqrt_to_minus)

        let (square_sum_c_sqrt_updated, carry) = uint256_mul(sum_c_sqrt_updated, sum_c_sqrt_updated)
        assert carry = Uint256(0, 0) # we dont support too large numbers

        # update our project accumulator
        project_accumulator.write(
                                    project_id=project_id, 
                                    value=ProjectAccumulator(sum_c=sum_c_updated, 
                                                             sum_c_sqrt=sum_c_sqrt_updated,
                                                             square_sum_c_sqrt=square_sum_c_sqrt_updated
                                                            )
                                 )

        # update total_project_contributed_fund
        let (old_total_project_contributed_fund) = total_project_contributed_fund.read()
        let (new_total_project_contributed_fund, add_carry) = uint256_add(old_total_project_contributed_fund, amount)
        assert add_carry = 0
        total_project_contributed_fund.write(new_total_project_contributed_fund)
    end

    # revoked reference related reassignment
    let syscall_ptr = syscall_ptr_temp
    let pedersen_ptr = pedersen_ptr_temp
    let range_check_ptr = range_check_ptr_temp

    # get current ProjectAccumulator again? (can we avoid this?)
    let (current_project_accumulator) = project_accumulator.read(project_id=project_id)

    # update c and c_sqrt. if previous has value, c_new = c_old + c_added (amount)
    let (c_new, add_carry) = uint256_add(c_old, amount)
    assert add_carry = 0
    let (c_sqrt_new) = uint256_sqrt(c_new)

    project_vote.write(project_id=project_id, voter_addr=voter_addr, value=ProjectVote(c=c_new, c_sqrt=c_sqrt_new))

    # add c to sum_c, add c to total_project_contributed_fund, add c_sqrt to sum_c_sqrt, 
    let (sum_c_new, add_carry) = uint256_add(c_new, current_project_accumulator.sum_c)
    assert add_carry = 0

    let (sum_c_sqrt_new, add_carry) = uint256_add(current_project_accumulator.sum_c_sqrt, c_sqrt_new)
    assert add_carry = 0

    # recalculate square_sum_c_sqrt
    let (square_sum_c_sqrt_new, carry) = uint256_mul(sum_c_sqrt_new, sum_c_sqrt_new)
    assert carry = Uint256(0, 0) # we dont support too large numbers

    project_accumulator.write(project_id=project_id, value=ProjectAccumulator(sum_c_new, sum_c_sqrt_new, square_sum_c_sqrt_new))
    return ()
end

func assert_project_exist{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt):

     with_attr error_message("Project id cannot be zero"):
            assert_not_zero(project_id)
     end

     with_attr error_message("Project does not exist"):
            let (current_id) = current_project_id.read()
            assert_lt(project_id, current_id)
     end

    return ()
end

func assert_only_within_voting_period{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

     let (timestamp) = get_block_timestamp()

     with_attr error_message("Cannot vote before vote time"):
            let (start_time) = vote_start_time.read()
            assert_le(start_time, timestamp)
     end

     with_attr error_message("Cannot vote after vote time"):
            let (end_time) = vote_end_time.read()
            assert_le(timestamp, end_time)
     end

     return ()
end