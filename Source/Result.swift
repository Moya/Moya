
public enum Result<T, Error: ErrorType> {
    case Success(T)
    case Failure(Error)

    public init(success: T){
        self = .Success(success)
    }
    
    public init(failure: Error) {
        self = .Failure(failure)
    }
}
