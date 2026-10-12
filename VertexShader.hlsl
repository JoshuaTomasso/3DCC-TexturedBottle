// an ultra simple hlsl vertex shader
#pragma pack_matrix(row_major)

cbuffer CameraMatrices : register(b0)
{
    float4x4 worldMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4 lightDirection;
    float4 lightColor;
    float4 sunAmbient;
    float4 cameraPosition;
}

StructuredBuffer<float4x4> instanceMatrices : register(t2, space2);

struct VSInput
{
    float3 position : POSITION;
    float3 normal : NORMAL;
    float2 texCoord : TEXCOORD;
    float4 tangent : TANGENT;
};

struct V_OUT
{
    float4 pos : SV_POSITION;
    float3 nrm : NORMAL;
    float2 uv : TEXCOORD_0;
    float4 tangent : TANGENT;
    float3 posW : POSITION;
};

V_OUT main(VSInput input)
{
    V_OUT output;
    
    // Apply world matrix to convert from right-handed to left-handed coordinate system
    float4 modelPosition = float4(input.position, 1.0);
    float4 worldPosition = mul(modelPosition, worldMatrix);
    
    // Save world position for lighting calculations
    output.posW = worldPosition.xyz;
    
    // Transform position through view and projection matrices
    float4 viewPosition = mul(worldPosition, viewMatrix);
    output.pos = mul(viewPosition, projectionMatrix);
    
    // Transform normal using world matrix (excluding translation)
    // CRITICAL: Apply the same world matrix to normals for correct lighting
    output.nrm = normalize(mul((float3x3) worldMatrix, input.normal));
    
    // Transform tangent vector properly
    float3 tangentVector = mul((float3x3) worldMatrix, input.tangent.xyz);
    output.tangent = float4(normalize(tangentVector), input.tangent.w);
    
    // Pass through texture coordinates
    output.uv = input.texCoord;
    
    return output;
}