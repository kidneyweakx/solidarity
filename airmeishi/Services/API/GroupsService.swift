//
//  GroupsService.swift
//  airmeishi
//
//  Group management endpoints
//

import Foundation

class GroupsService {
    private let client: APIClient
    
    init(client: APIClient = .shared) {
        self.client = client
    }
    
    /// POST /groups/groups/create
    func createGroup(_ payload: GroupCreateRequest) async -> CardResult<GroupCreateResponse> {
        return await client.request(
            path: "groups/groups/create",
            method: .POST,
            body: payload,
            decodeAs: GroupCreateResponse.self
        )
    }
    
    /// GET /groups/groups/{groupId}/root
    func getRoot(groupId: String) async -> CardResult<GroupRootResponse> {
        return await client.request(
            path: "groups/groups/\(groupId)/root",
            decodeAs: GroupRootResponse.self
        )
    }
    
    /// POST /groups/groups/{groupId}/add-member
    func addMember(groupId: String, payload: AddMemberRequest) async -> CardResult<AddMemberResponse> {
        return await client.request(
            path: "groups/groups/\(groupId)/add-member",
            method: .POST,
            body: payload,
            decodeAs: AddMemberResponse.self
        )
    }
    
    /// POST /groups/groups/{groupId}/revoke
    func revokeMember(groupId: String, payload: RevokeMemberRequest) async -> CardResult<RevokeMemberResponse> {
        return await client.request(
            path: "groups/groups/\(groupId)/revoke",
            method: .POST,
            body: payload,
            decodeAs: RevokeMemberResponse.self
        )
    }
}


