import torch as th
import torch.nn as nn
from stable_baselines3.common.torch_layers import BaseFeaturesExtractor


class ClinicFeatureExtractor(BaseFeaturesExtractor):
   

    def __init__(self, observation_space, features_dim: int = 128):
        super().__init__(observation_space, features_dim)

        in_dim = observation_space.shape[0]

        self.net = nn.Sequential(
            nn.Linear(in_dim, 256),
            nn.ReLU(),
            nn.Linear(256, 128),
            nn.ReLU(),
        )

        # features_dim là output cuối cùng của extractor
        self._features_dim = features_dim

    def forward(self, x: th.Tensor) -> th.Tensor:
        return self.net(x)
