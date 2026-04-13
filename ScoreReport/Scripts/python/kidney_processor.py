import sys
import pandas as pd
import xgboost as xgb
from sklearn.metrics import accuracy_score, roc_auc_score
import numpy as np

class XGBoostPredictor:
    def __init__(self, random_seed=42):
        self.RANDOM_SEED = random_seed
        np.random.seed(self.RANDOM_SEED)
        
    def load_model_and_params(self, model_path):
        """加载模型参数和预训练模型"""
        # 初始化并加载模型
        self.model = xgb.XGBClassifier()
        self.model.load_model(model_path)
        # 这个是训练数据的比重
        self.model.set_params(base_score=0.5612296)
        
        # 获取base_score
        self.booster = self.model.get_booster()
        self.base_score = self.booster.attr("base_score")
        # print(f"Trained model's base_score: {self.base_score}")
        
    def load_and_prepare_data(self, data):
        """加载和准备数据"""
        df1 = pd.DataFrame([data], columns=['T2信号', '皮髓质期', '微观脂肪', 'SEI', 'ADER≧1.5', '弥散受限', 'label'])
        self.X = df1
    
    def predict(self, input_data):
        """进行预测"""
        # 直接使用输入的DataFrame进行预测
        probabilities = self.model.predict_proba(input_data)
        predictions = self.model.predict(input_data)
        return predictions, probabilities
    
    def evaluate(self, y_true, y_pred, y_prob):
        """评估模型性能"""
        accuracy = accuracy_score(y_true, y_pred)
        auc = roc_auc_score(y_true, y_prob[:, 1])  # 使用正类的概率
        return accuracy, auc

def calculate_CCRCC(T2_signal, skin_signal, micro_signal, SEI_signal, ADER_signal, dispersion_signal, ccls):
    predictor = XGBoostPredictor()
    model_path = 'Scripts/model/model_fold_1.json'
    predictor.load_model_and_params(model_path)
    data = [T2_signal, skin_signal, micro_signal, SEI_signal, ADER_signal, dispersion_signal, ccls]
    predictor.load_and_prepare_data(data)
    predictions, probabilities = predictor.predict(predictor.X)
    return str(probabilities[0][1])


def CCLS(T2_signal, skin_signal, micro_signal, SEI_signal, ADER_signal, dispersion_signal):
    """
    核心决策树逻辑
    参数需为字符串类型的 '0', '1', '2' 等。
    """
    # T2_signal = 0:低信号, 1:中信号, 2:高信号
    if T2_signal == "0":  # 低信号
        if skin_signal == "0":  # 轻度强化
            if micro_signal == "0":  # 无
                return 1
            elif micro_signal == "1":  # 有
                return 3
        elif skin_signal == "1":  # 中度强化
            return 3
        elif skin_signal == "2":  # 明显强化
            if ADER_signal == "0":  # 无
                if dispersion_signal == "0":  # 无
                    return 4
                elif dispersion_signal == "1":  # 有
                    return 3
            elif ADER_signal == "1":  # 有
                if dispersion_signal == "0":  # 无
                    return 3
                elif dispersion_signal == "1":  # 有
                    return 2
                    
    elif T2_signal == "1":  # 中信号
        if skin_signal == "0":  # 轻度强化
            if micro_signal == "0":  # 无
                if dispersion_signal == "0":  # 无
                    return 2
                elif dispersion_signal == "1":  # 有
                    return 1
            elif micro_signal == "1":  # 有
                return 3
        elif skin_signal == "1":  # 中度强化
            if micro_signal == "0":  # 无
                if SEI_signal == "0":  # 无
                    return 3
                elif SEI_signal == "1":  # 有
                    return 2
            elif micro_signal == "1":  # 有
                return 3
        elif skin_signal == "2":  # 明显强化
            if micro_signal == "0":  # 无
                if SEI_signal == "0":  # 无
                    return 4
                elif SEI_signal == "1":  # 有
                    return 3
            elif micro_signal == "1":  # 有
                return 5
                
    elif T2_signal == "2":  # 高信号
        if skin_signal == "0":  # 轻度强化
            return 3
        elif skin_signal == "1":  # 中度强化
            if micro_signal == "0":  # 无
                if SEI_signal == "0":  # 无
                    return 3
                elif SEI_signal == "1":  # 有
                    return 2
            elif micro_signal == "1":  # 有
                return 3
        elif skin_signal == "2":  # 明显强化
            if micro_signal == "0":  # 无
                if SEI_signal == "0":  # 无
                    return 4
                elif SEI_signal == "1":  # 有
                    return 3
            elif micro_signal == "1":  # 有
                return 5
    
    return 0

def calculate_CCLS(T2_signal_in, skin_signal_in, micro_signal_in, SEI_signal_in, ADER_signal_in, dispersion_signal_in):
    """
    接收数值输入，转换为字符串并调用核心 CCLS 逻辑，最后返回计算结果。
    """
    # 将输入转换为字符串以匹配 CCLS 内部的字符串逻辑判断
    ccls = CCLS(str(T2_signal_in), str(skin_signal_in), str(micro_signal_in), 
                str(SEI_signal_in), str(ADER_signal_in), str(dispersion_signal_in))
    result = 0.0
    if ccls == 1:
        result = 0.05
    elif ccls == 2:
        result = 0.06
    elif ccls == 3:
        result = 0.35
    elif ccls == 4:
        result = 0.78
    elif ccls == 5:
        result = 0.93
        
    return result

if __name__ == "__main__":
    # 检查是否有命令行参数
    if len(sys.argv) == 7:
        # 通过命令行参数调用（来自Qt程序）
        try:
            inputs = [int(sys.argv[i]) for i in range(1, 7)]
            ccls = calculate_CCLS(*inputs)
            ccrcc = calculate_CCRCC(*inputs, ccls)
            print(f"result ccls: {ccls}")
            print(f"result ccrcc: {ccrcc}")
        except ValueError:
            print("ValueError!!!")
        except Exception as e:
            print(f"error!!!: {e}")
    else:
        # 交互式输入模式
        print("请输入6个参数 (用空格分隔):")
        print("T2信号 (0:低, 1:中, 2:高)")
        print("皮髓质期信号 (0:轻度, 1:中度, 2:明显)")
        print("微观脂肪 (0:无, 1:有)")
        print("SEI (0:无, 1:有)")
        print("ADER (0:无, 1:有)")
        print("弥散受限 (0:无, 1:有)")
        print("例如: 1 2 0 1 0 0")
        
        try:
            user_input = input("> ").strip().split()
            if len(user_input) != 6:
                print("错误: 必须输入 6 个数字。")
            else:
                inputs = [int(x) for x in user_input]
                ccls = calculate_CCLS(*inputs)
                ccrcc = calculate_CCRCC(*inputs, ccls)
                print(f"result ccls: {ccls}")
                print(f"result ccrcc: {ccrcc}")
        except ValueError:
            print("输入错误: 请输入整数。")
        except Exception as e:
            print(f"发生错误: {e}")
