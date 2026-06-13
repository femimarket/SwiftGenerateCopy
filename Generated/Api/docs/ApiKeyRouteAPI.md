# ApiKeyRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**apiKey**](ApiKeyRouteAPI.md#apikey) | **POST** /api_key | 


# **apiKey**
```swift
    open class func apiKey(id: UUID, userId: String, key: String? = nil, completion: @escaping (_ data: ApiKey?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let id = 987 // UUID | 
let userId = "userId_example" // String | 
let key = "key_example" // String |  (optional)

ApiKeyRouteAPI.apiKey(id: id, userId: userId, key: key) { (response, error) in
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
 **id** | **UUID** |  | 
 **userId** | **String** |  | 
 **key** | **String** |  | [optional] 

### Return type

[**ApiKey**](ApiKey.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

