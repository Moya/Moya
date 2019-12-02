# Migration Guide from 14.x to 15.x

This project follows [Semantic Versioning](http://semver.org).

## Task revamp

Through additions of cases to always allow more usages, `Task`  have grown a bit too much. With Swift 5.1 allowing the usage of default values in enumeration cases, it is now possible to reduce the number of cases while keeping the same functionalities as before. 

### New values

If the old `Task` value starts with “request”, use the new `Task.request` value.

If the old `Task` value starts with “upload”, use the new `Task.upload` value.

If the old `Task` value starts with “download”, use the new `Task.download` value.



### Determining associated values

#### Body parameters
If the old `Task` was `.requestData` or `.requestCompositeData`: the `bodyParams` associated value should be `.raw(data)`.

If the old `Task` was `.requestJSONEncodable`, `.requestCompositeData`, or was using a `JSONEncoding` associated value: the new `bodyParams` associated value should be `.json(encodable)`, or `.json(encodable, encoder: <aCustomEncoder>)` if you need to provide a custom encoder.

If the old `Task` was  `.requestCompositeParameters`, `.downloadParameters` or was using an `URLEncoding` associated value with a `.httpBody` destination: the new `bodyParams` associated value should be `.urlEncoded(encodable)` or `.urlEncoded(encodable, encoder: <aCustomEncoder>)` if you need to provide a custom encoder.

If you are not concerned by any of the points above, you don't need to provide the `bodyParams` associated value.

#### URL parameters
If the old `Task` was `.requestCompositeData`, `.requestCompositeParameters`, `.uploadCompositeMultipart` or was using a `URLEncoding` associated value with a `.queryString` destination: you should provide the new `urlParams` associated value.

If you are not concerned by the point above, you don't need to provide the `urlParams` associated value.

#### Custom parameters
If the old `Task` was `.requestParameters` or `.downloadParameters` with a `ParameterEncoding` associated value that was not `JSONEncoding` or `URLEncoding`: you should provide the new `customParams` associated value.

If you are not concerned by the point above, you don't need to provide the `customParams` associated value.


#### UploadSource
If the old `Task` value was `.uploadFile` : you should use `.file`.
If the old `Task` value was `.uploadMultipart` : you should use `.multipart`.
