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
        // オブジェクト描画範囲 中心(0, 0, 0) XYZ -500 ~ 500の立方体 のバウンディングボックスの定義
        drawBounds = new Bounds(Vector3.zero, Vector3.one * 1000f);

        // GPUに渡すバッファの定義　(構造体型データ格納, 描画するオブジェクトの複製数, 3D行列のfloat4x4サイズ)
        matrixBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, instanceCount, sizeof(float) * 16);

        // ベース位置バッファ（xyz: 位置、w: インスタンスID等の利用）
        basePositionBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, instanceCount, sizeof(float) * 4);
        Vector4[] basePositions = new Vector4[instanceCount];
        for (int i = 0; i < instanceCount; i++)
        {
            basePositions[i] = new Vector4(
                Random.Range(-50f, 50f),
                0f,
                Random.Range(-50f, 50f),
                i // インスタンスID
            );
        }

        // バッファにinstanceCountの数だけ出力する座標を指定するデータを格納
        basePositionBuffer.SetData(basePositions);

        // Compute Shader 設定
        kernelID = computeShader.FindKernel("CSMain"); // Compute Shaderのカーネル名を指定
        computeShader.GetKernelThreadGroupSizes(kernelID, out threadGroupSizeX, out _, out _); // ComputeShaderで実行されるメイン関数のスレッド数　[numthreads(64, 1, 1)]　1は_で省略

        
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
