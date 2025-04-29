//-------------------- Vertex Shader --------------------

struct VertexFactory
{
	float3 position : POSITION;

	float3 normal : NORMAL;

	float3 tangent : TANGENT;

	float2 uv : TEXCOORD;
};


struct VertexOutput
{
	/// Vertex world position
	float3 worldPosition : POSITION;

	/// Shader view position
	float4 svPosition : SV_POSITION;

	/// Camera view position.
	float3 viewPosition : VIEW_POSITION;


	/// TBN (tangent, bitangent, normal) transformation matrix.
	float3x3 TBN : TBN;


	/// Vertex UV
	float2 uv : TEXCOORD;
};

//---------- Bindings ----------
struct Camera
{
	/// Camera transformation matrix.
	float4x4 view;

	/**
	*	Camera inverse view projection matrix.
	*	projection * inverseView.
	*/
	float4x4 invViewProj;
};
cbuffer CameraBuffer : register(b0)
{
	Camera camera;
};

struct Object
{
	/// Object transformation matrix.
	float4x4 transform;
};
cbuffer ObjectBuffer : register(b1)
{
	Object object;
};


VertexOutput main(VertexFactory _input)
{
	VertexOutput output;

	//---------- Position ----------
	const float4 worldPosition4 = mul(object.transform, float4(_input.position, 1.0));
	output.worldPosition = worldPosition4.xyz / worldPosition4.w;
	output.svPosition = mul(camera.invViewProj, worldPosition4);
	output.viewPosition = float3(camera.view._14, camera.view._24, camera.view._34);


	//---------- Normal ----------
	const float3 normal = normalize(mul((float3x3)object.transform, _input.normal));
	const float3 tangent = normalize(mul((float3x3)object.transform, _input.tangent));
	const float3 bitangent = cross(normal, tangent);

	/// HLSL uses row-major constructor: transpose to get TBN matrix.
	output.TBN = transpose(float3x3(tangent, bitangent, normal));


	//---------- UV ----------
	output.uv = _input.uv;

	return output;
}
