# SolanaRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**solana**](SolanaRouteAPI.md#solana) | **POST** /solana | 


# **solana**
```swift
    open class func solana(amountCents: Int64, id: UUID, pubkey: String, status: Status, userId: String, credit: Int64? = nil, loaded: Bool? = nil, quotedOutUnits: Int64? = nil, requestId: String? = nil, signature: String? = nil, signedTx: String? = nil, unsignedTx: String? = nil, completion: @escaping (_ data: Solana?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let amountCents = 987 // Int64 | 
let id = 987 // UUID | 
let pubkey = "pubkey_example" // String | 
let status = Status() // Status | 
let userId = "userId_example" // String | 
let credit = 987 // Int64 |  (optional)
let loaded = true // Bool |  (optional)
let quotedOutUnits = 987 // Int64 |  (optional)
let requestId = "requestId_example" // String |  (optional)
let signature = "signature_example" // String |  (optional)
let signedTx = "signedTx_example" // String |  (optional)
let unsignedTx = "unsignedTx_example" // String |  (optional)

SolanaRouteAPI.solana(amountCents: amountCents, id: id, pubkey: pubkey, status: status, userId: userId, credit: credit, loaded: loaded, quotedOutUnits: quotedOutUnits, requestId: requestId, signature: signature, signedTx: signedTx, unsignedTx: unsignedTx) { (response, error) in
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
 **amountCents** | **Int64** |  | 
 **id** | **UUID** |  | 
 **pubkey** | **String** |  | 
 **status** | [**Status**](Status.md) |  | 
 **userId** | **String** |  | 
 **credit** | **Int64** |  | [optional] 
 **loaded** | **Bool** |  | [optional] 
 **quotedOutUnits** | **Int64** |  | [optional] 
 **requestId** | **String** |  | [optional] 
 **signature** | **String** |  | [optional] 
 **signedTx** | **String** |  | [optional] 
 **unsignedTx** | **String** |  | [optional] 

### Return type

[**Solana**](Solana.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

