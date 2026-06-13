# ChatRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**chat**](ChatRouteAPI.md#chat) | **POST** /chat | 


# **chat**
```swift
    open class func chat(id: UUID, messages: [ChatMessage], credit: Int64? = nil, userId: String? = nil, completion: @escaping (_ data: Chat?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let id = 987 // UUID | 
let messages = [ChatMessage(content: "content_example", role: Role())] // [ChatMessage] | 
let credit = 987 // Int64 |  (optional)
let userId = "userId_example" // String |  (optional)

ChatRouteAPI.chat(id: id, messages: messages, credit: credit, userId: userId) { (response, error) in
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
 **messages** | [**[ChatMessage]**](ChatMessage.md) |  | 
 **credit** | **Int64** |  | [optional] 
 **userId** | **String** |  | [optional] 

### Return type

[**Chat**](Chat.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

