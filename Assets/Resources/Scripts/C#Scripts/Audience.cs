using UnityEngine;
using Unity.Mathematics;

[System.Serializable]
public struct Audience
{
    public int2 seatPerBlock;   // 1ブロックあたりの席数　x: 横の座席数, y: 縦の座席数
    public float2 seatPitch;    // 席ごとの間隔          x: 横の間隔, y: 縦の間隔
    public int2 blockCount;     // ブロック数            x: 横のブロック数, y: 縦のブロック数
    public float2 aisleWidth;   // 通路(ブロック間)の幅   x: 横の幅, y: 縦の幅
    public float swingFrequency; // ペンライトの揺れ周波数
    public float swingOffset;   // ペンライトの揺れオフセット

    public static Audience Default() => new Audience
    {
        seatPerBlock = new int2(8, 12),
        seatPitch = new float2(0.4f, 0.8f),
        blockCount = new int2(7, 3),
        aisleWidth = new float2(0.7f, 1.2f),
        swingFrequency = 1.0f,
        swingOffset = 1.0f
    };

    public int BlockSeatCount => seatPerBlock.x * seatPerBlock.y;               // 1ブロックあたりの席数
    public int TotalSeatCount => BlockSeatCount * blockCount.x * blockCount.y;  // 総席数

    /// <summary>
    /// 座席のインスタンスIDからブロックと座標を取得
    /// </summary>
    public (int2 block, int2 seat) GetCoordinatesFromIndex(int i)
    {
        var si = i / BlockSeatCount;
        var pi = i - BlockSeatCount * si;
        var sy = si / blockCount.x;
        var sx = si - blockCount.x * sy;
        var py = pi / seatPerBlock.x;
        var px = pi - seatPerBlock.x * py;
        return (new int2(sx, sy), new int2(px, py));
    }

    /// <summary>
    /// 座席からシーン上に配置される座標を取得
    /// </summary>
    public float2 GetPositionOnPlane(int2 block, int2 seat)
    {
        return seatPitch * (seat - (float2)(seatPerBlock - 1) * 0.5f)
             + (seatPitch * (seatPerBlock - 1) + aisleWidth)
             * (block - (float2)(blockCount - 1) * 0.5f);
    }
}