# SolanaRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**solana**](SolanaRouteAPI.md#solana) | **POST** /solana | 


# **solana**
```swift
    open class func solana(userId: String, byColumn: SolanaByColumn? = nil, byFields: SolanaByFields? = nil, byId: SolanaById? = nil, delete: SolanaDelete? = nil, paginate: SolanaPaginate? = nil, search: SolanaSearch? = nil, update: SolanaUpdate? = nil, upsert: SolanaUpsert? = nil, completion: @escaping (_ data: SolanaServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = solana.ByColumn(column: "column_example", data: [Solana(amountCents: 123, credit: 123, id: 123, loaded: false, pubkey: "pubkey_example", quotedOutUnits: 123, requestId: "requestId_example", signature: "signature_example", signedTx: "signedTx_example", status: Status(), unsignedTx: "unsignedTx_example", userId: "userId_example")], value: 123) // SolanaByColumn |  (optional)
let byFields = solana.ByFields(data: [Solana(amountCents: 123, credit: 123, id: 123, loaded: false, pubkey: "pubkey_example", quotedOutUnits: 123, requestId: "requestId_example", signature: "signature_example", signedTx: "signedTx_example", status: Status(), unsignedTx: "unsignedTx_example", userId: "userId_example")], fields: [solana.ByFieldsQuery(path: "path_example", value: "value_example")]) // SolanaByFields |  (optional)
let byId = solana.ById(data: Solana(amountCents: 123, credit: 123, id: 123, loaded: false, pubkey: "pubkey_example", quotedOutUnits: 123, requestId: "requestId_example", signature: "signature_example", signedTx: "signedTx_example", status: Status(), unsignedTx: "unsignedTx_example", userId: "userId_example"), id: 123) // SolanaById |  (optional)
let delete = solana.Delete(data: [123]) // SolanaDelete |  (optional)
let paginate = solana.Paginate(data: [Solana(amountCents: 123, credit: 123, id: 123, loaded: false, pubkey: "pubkey_example", quotedOutUnits: 123, requestId: "requestId_example", signature: "signature_example", signedTx: "signedTx_example", status: Status(), unsignedTx: "unsignedTx_example", userId: "userId_example")], skip: 123, take: 123) // SolanaPaginate |  (optional)
let search = solana.Search(data: [Solana(amountCents: 123, credit: 123, id: 123, loaded: false, pubkey: "pubkey_example", quotedOutUnits: 123, requestId: "requestId_example", signature: "signature_example", signedTx: "signedTx_example", status: Status(), unsignedTx: "unsignedTx_example", userId: "userId_example")], query: "query_example") // SolanaSearch |  (optional)
let update = solana.Update(data: [Solana(amountCents: 123, credit: 123, id: 123, loaded: false, pubkey: "pubkey_example", quotedOutUnits: 123, requestId: "requestId_example", signature: "signature_example", signedTx: "signedTx_example", status: Status(), unsignedTx: "unsignedTx_example", userId: "userId_example")], inputs: [solana.UpdateItem(fields: "TODO", id: 123)]) // SolanaUpdate |  (optional)
let upsert = solana.Upsert(data: [Solana(amountCents: 123, credit: 123, id: 123, loaded: false, pubkey: "pubkey_example", quotedOutUnits: 123, requestId: "requestId_example", signature: "signature_example", signedTx: "signedTx_example", status: Status(), unsignedTx: "unsignedTx_example", userId: "userId_example")]) // SolanaUpsert |  (optional)

SolanaRouteAPI.solana(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String** |  | 
 **byColumn** | [**SolanaByColumn**](SolanaByColumn.md) |  | [optional] 
 **byFields** | [**SolanaByFields**](SolanaByFields.md) |  | [optional] 
 **byId** | [**SolanaById**](SolanaById.md) |  | [optional] 
 **delete** | [**SolanaDelete**](SolanaDelete.md) |  | [optional] 
 **paginate** | [**SolanaPaginate**](SolanaPaginate.md) |  | [optional] 
 **search** | [**SolanaSearch**](SolanaSearch.md) |  | [optional] 
 **update** | [**SolanaUpdate**](SolanaUpdate.md) |  | [optional] 
 **upsert** | [**SolanaUpsert**](SolanaUpsert.md) |  | [optional] 

### Return type

[**SolanaServerRequest**](SolanaServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

