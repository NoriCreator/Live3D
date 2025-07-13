// Unity用：Compute Shaderで位置情報生成、モーションはシェーダー側で制御（ペンライト用途）

using UnityEngine;

public class InstancedObjectRenderer : MonoBehaviour
{
    [Header("描画対象のメッシュとマテリアル")]
    public Mesh instanceMesh;
    public Material instanceMaterial;
    public ComputeShader computeShader;

    [Header("インスタンス数")]
    public int instanceCount = 100;

    private GraphicsBuffer matrixBuffer;
    private GraphicsBuffer basePositionBuffer;
    private Bounds drawBounds;

    private int kernelID;
    private uint threadGroupSizeX;

    void Start()
    {
        // 描画範囲設定（広域に）
        drawBounds = new Bounds(Vector3.zero, Vector3.one * 1000f);

        // インスタンス行列バッファ
        matrixBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, instanceCount, sizeof(float) * 16);

        // ベース位置バッファ（xyz: 位置、w: インスタンスIDなどに利用可）
        basePositionBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, instanceCount, sizeof(float) * 4);
        Vector4[] basePositions = new Vector4[instanceCount];
        for (int i = 0; i < instanceCount; i++)
        {
            basePositions[i] = new Vector4(
                Random.Range(-50f, 50f),
                0f,
                Random.Range(-50f, 50f),
                i // 任意の識別値として
            );
        }
        basePositionBuffer.SetData(basePositions);

        // Compute Shader 設定
        kernelID = computeShader.FindKernel("CSMain");
        computeShader.GetKernelThreadGroupSizes(kernelID, out threadGroupSizeX, out _, out _);

        computeShader.SetBuffer(kernelID, "Result", matrixBuffer);
        computeShader.SetBuffer(kernelID, "BasePosition", basePositionBuffer);
        computeShader.SetInt("instanceCount", instanceCount);

        // 初回実行
        DispatchComputeShader();

        // マテリアルにバッファを渡す
        instanceMaterial.SetBuffer("matrixBuffer", matrixBuffer);
        instanceMaterial.SetBuffer("basePositionBuffer", basePositionBuffer);
    }

    void DispatchComputeShader()
    {
        int threadGroupsX = Mathf.CeilToInt(instanceCount / (float)threadGroupSizeX);
        computeShader.Dispatch(kernelID, threadGroupsX, 1, 1);
    }

    void Update()
    {
        // 毎フレーム位置は一定、モーションはシェーダー側で処理
        Graphics.DrawMeshInstancedProcedural(instanceMesh, 0, instanceMaterial, drawBounds, instanceCount);
    }

    void OnDestroy()
    {
        matrixBuffer?.Release();
        basePositionBuffer?.Release();
    }
}
