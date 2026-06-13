# ImageRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**image**](ImageRouteAPI.md#image) | **POST** /image | 


# **image**
```swift
    open class func image(file: String, id: UUID, credit: Int64? = nil, userId: String? = nil, completion: @escaping (_ data: Image?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let file = "file_example" // String | 
let id = 987 // UUID | 
let credit = 987 // Int64 |  (optional)
let userId = "userId_example" // String |  (optional)

ImageRouteAPI.image(file: file, id: id, credit: credit, userId: userId) { (response, error) in
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
 **file** | **String** |  | 
 **id** | **UUID** |  | 
 **credit** | **Int64** |  | [optional] 
 **userId** | **String** |  | [optional] 

### Return type

[**Image**](Image.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

