module GaussianProcesses_

export GPClassifier

import MLJBase

using CategoricalArrays

import GaussianProcesses

const GP = GaussianProcesses

GPClassifierFitResultType{T} =
    Tuple{GP.GPE,
    MLJBase.CategoricalDecoder{UInt32,T,1,UInt32}}

# XXX it should probably be a probabilistic classifier instead of deterministic
# but the GaussianProcesses.predict_y is deterministic (returns mean/var)

mutable struct GPClassifier{T, M<:GP.Mean, K<:GP.Kernel} <: MLJBase.Probabilistic{GPClassifierFitResultType{T}}
    target_type::Type{T} # target is CategoricalArray{target_type}
    mean::M
    kernel::K
    logNoise::Float64
end

function GPClassifier(
    ; target_type=Int
    , mean=GP.MeanZero()
    , kernel=GP.SE(0.0, 1.0)
    , logNoise=-2.0)

    model = GPClassifier(
        target_type
        , mean
        , kernel
        , logNoise)

    message = MLJBase.clean!(model)
    isempty(message) || @warn message

    return model
end

# function MLJBase.clean!

function MLJBase.fit(model::GPClassifier{T2,M,K}
            , verbosity::Int
            , X::Matrix{Float64}
            , y::CategoricalVector{T}) where {T,T2,M,K}

    T == T2 || throw(ErrorException("Type, $T, of target incompatible "*
                                    "with type, $T2, of $model."))

    decoder = MLJBase.CategoricalDecoder(y)
    y_plain = MLJBase.transform(decoder, y)

    gp = GP.GPE(X'
                , y_plain
                , model.mean
                , model.kernel
                , model.logNoise)

    fit!(gp, X', y_plain)

    fitresult = (gp, decoder)

    cache = nothing
    report = nothing

    return fitresult, cache, report
end

MLJBase.coerce(model::GPClassifier, Xtable) = MLJBase.matrix(Xtable)

function MLJBase.predict(model::GPClassifier{T}
                    , fitresult
                    , Xnew) where T
    gp, decoder = fitresult
    return MLJBase.inverse_transform(decoder, GP.predict_y(gp, Xnew'))
end

# metadata:
MLJBase.package_name(::Type{<:GPClassifier}) = "GaussianProcesses"
MLJBase.package_uuid(::Type{<:GPClassifier}) = "unknown"
MLJBase.is_pure_julia(::Type{<:GPClassifier}) = :yes
MLJBase.inputs_can_be(::Type{<:GPClassifier}) = [:numeric, ]
MLJBase.target_kind(::Type{<:GPClassifier}) = :multiclass
MLJBase.target_quantity(::Type{<:GPClassifier}) = :univariate

end # module

using .GaussianProcesses_
export GPClassifier
